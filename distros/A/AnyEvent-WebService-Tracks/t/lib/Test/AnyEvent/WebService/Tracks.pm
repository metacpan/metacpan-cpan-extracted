package Test::AnyEvent::WebService::Tracks;

use strict;
use warnings;

our $VERSION = '0.01';

use AnyEvent;
use AnyEvent::WebService::Tracks;
use Test::More ();

my $tracks;

sub get_tracks {
    return $tracks;
}

sub clear_tracks {
    my $cond = AnyEvent->condvar;

    my $clear_contexts;
    my $clear_projects;
    my $clear_todos;

    $clear_contexts = sub {
        my ( $contexts ) = @_;

        if(@$contexts) {
            my $context = shift @$contexts;
            $context->destroy(sub {
                $clear_contexts->($contexts);
            });
        } else {
            $cond->send;
        }
    };

    $clear_projects = sub {
        my ( $projects ) = @_;

        if(@$projects) {
            my $project = shift @$projects;
            $project->destroy(sub {
                $clear_projects->($projects);
            });
        } else {
            $tracks->contexts($clear_contexts);
        }
    };

    $clear_todos = sub {
        my ( $todos ) = @_;

        if(@$todos) {
            my $todo = shift @$todos;
            $todo->destroy(sub {
                $clear_todos->($todos);
            });
        } else {
            $tracks->projects($clear_projects);
        }
    };

    $tracks->todos($clear_todos);
    $cond->recv;
}

sub run_tests_in_loop (&) {
    my ( $cb ) = @_;
    my ( undef, $file, $line ) = caller;

    my $cond = AnyEvent->condvar;

    my $timer_has_fired = 0;
    my $timer = AnyEvent->timer(
        after => 30,
        cb    => sub {
            $timer_has_fired = 1;
            Test::More::fail("Timeout at $file, line $line");
            $cond->send;
        },
    );

    eval {
        $cb->($cond);
    };
    if($@) {
        Test::More::fail($@);
    } else {
        $cond->recv;
        Test::More::pass unless $timer_has_fired;
    }
}

sub import {
    my ( undef, @args ) = @_;

    my $pkg = caller;

    no strict 'refs';
    foreach (@Test::More::EXPORT) {
        *{$pkg . '::' . $_} = \&{'Test::More::' . $_};
    }
    *{$pkg . '::get_tracks'}          = \&get_tracks;
    *{$pkg . '::clear_tracks'}        = \&clear_tracks;
    *{$pkg . '::run_tests_in_loop'}   = \&run_tests_in_loop;

    if($ENV{'TRACKS_URL'}  &&
           $ENV{'TRACKS_USER'} &&
           $ENV{'TRACKS_PASS'}) {
        $tracks = AnyEvent::WebService::Tracks->new(
            url      => $ENV{'TRACKS_URL'},
            username => $ENV{'TRACKS_USER'},
            password => $ENV{'TRACKS_PASS'},
        );

        Test::More::plan @args if @args;
    } else {
        Test::More::plan skip_all => 'Please define TRACKS_URL, TRACKS_USER, and TRACKS_PASS and point them to an *empty* Tracks installation.  THESE TESTS WILL ERASE ALL YOUR DATA!';
    }
}

1;
