#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use JSON;
use Data::Dumper;
use AnyEvent::Open3::Simple;
use EV;

use blib;
use AnyEvent::Beanstalk::Worker;

my $w = AnyEvent::Beanstalk::Worker->new(
    max_jobs          => 1,
    initial_state     => 'run',
    beanstalk_watch   => 'ssh-jobs',
    beanstalk_decoder => sub {
        eval { decode_json(shift) };
    }
);

$w->on(
    run => sub {
        my $self = shift;
        my ( $qjob, $qresp ) = @_;
        my $job = $qjob->decode;

        my $cv      = AnyEvent->condvar(
            cb => sub {
                my ($results, $res_out, $res_err) = $_[0]->recv;
                say "success or fail: " . Dumper($results);
                say "script stdout: " . Dumper($res_out);
                say "script stderr: " . Dumper($res_err);

                $self->finish( delete => $qjob->id );
            }
        );

        my %results = ();
        my %stdout  = ();
        my %stderr  = ();
        $cv->begin( sub { $_[0]->send( \%results, \%stdout, \%stderr ) } );
        run_scripts( $cv, $job->{target}, $job->{scripts}, \%results, \%stdout, \%stderr );
        $cv->end;
    }
);

$w->start;

say STDERR "ctrl-c/SIGINT to stop";

EV::run;

exit;

sub run_scripts {
    my $cv_done = shift;
    my $target  = shift;
    my $scripts = shift;

    my $results = shift;
    my $stdout  = shift;
    my $stderr  = shift;

    my $ipc = AnyEvent::Open3::Simple->new(
        on_start => sub {
            my $proc = shift;
            AE::log trace => "pid: " . $proc->pid;
        },

        on_stdout => sub {
            my $proc = shift;
            my $line = shift;
            AE::log trace => $proc->pid . " stdout: " . $line;
            $stdout->{$proc->pid} .= $line . "\n";
        },

        on_stderr => sub {
            my $proc = shift;
            my $line = shift;
            AE::log trace => $proc->pid . " stderr: " . $line;
            $stderr->{$proc->pid} .= $line . "\n";
        },

        on_exit => sub {
            my $proc  = shift;
            my $exval = shift;
            my $sig   = shift;

            AE::log trace => $proc->pid . " exit: $exval" if $exval;
            AE::log trace => $proc->pid . " signal: $sig" if $sig;
        },

        on_error => sub {
            my $err = shift;
            AE::log warn => $err;
            $cv_done->end;
        },

        on_success => sub {
            my $proc = shift;
            AE::log info => "success for " . $proc->pid;
            $results->{ $proc->pid } = 1;
            $cv_done->end;
        },

        on_fail => sub {
            my $proc = shift;
            AE::log error => "fail for " . $proc->pid;
            $results->{ $proc->pid } = 0;
            $cv_done->end;
        }
    );

    for my $scr (@$scripts) {
        $cv_done->begin;
        my ( $intr, $script ) = ( $scr->{interpreter}, $scr->{script} );
        $ipc->run( "ssh", "-o", "ConnectTimeout=3", $target, $intr, \$script );
    }
}
