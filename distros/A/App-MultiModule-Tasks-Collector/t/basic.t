#!env perl

use strict;
use warnings FATAL => 'all';
use IPC::Transit;
use File::Slurp;
use File::Temp qw/tempfile tempdir/;
use Data::Dumper;
use POSIX ":sys_wait_h";
use Test::More;
use lib '../lib';

use_ok('App::MultiModule::Tasks::Collector');

BEGIN {
    use_ok('App::MultiModule') || die "Failed to load App::MultiModule\n";
    use_ok('App::MultiModule::Test') || die "Failed to load App::MultiModule::Test\n";
    use_ok('App::MultiModule::Test::Collector') || die "Failed to load App::MultiModule::Test::Collector\n";
}

App::MultiModule::Test::begin();
App::MultiModule::Test::Collector::_begin();

my (undef, $errors_log) = tempfile();
my $collectors_dir = tempdir(CLEANUP => 1);
my $collectors_include_path = "$collectors_dir/lib";
mkdir $collectors_include_path;
my $collectors_path = "$collectors_dir/lib/Collectors";
mkdir $collectors_path;
{   open my $fh, '>', "$collectors_path/collector1.pm";
    print $fh qpackage Collectors::collector1;
use base 'App::MultiModule::Collector';

sub collect {
    my $self = shift;
    my $config = shift; #optional, gets {Collector}->{collectors}->{collector1}
    my %args = @_; #everything else
    $self->emit({something => 'cool'});
}
1;
;
    close $fh;
}

my $args = "-q tqueue -p MultiModuleTest:: -o error:$errors_log";
ok my $daemon_pid = App::MultiModule::Test::run_program($args), 'run_program';
END { #just to be damn sure
    kill 9, $daemon_pid;
    unlink $errors_log;
};

my $config = {
    '.multimodule' => {
        config => {
            Collector => {
                collectors_path => $collectors_include_path,
                collectors => {
                    collector1 => {
                        interval => 2,
                        class => 'Collectors::collector1',
                        other => 'stuff',
                        timeout => 1,
                    }
                }
            },
            MultiModule => {
            },
            Router => {  #router config
                routes => [
                    {   match => {
                            source => 'Collector',
                            collector_name => 'collector1',
                        },
                        forwards => [
                            {   qname => 'test_out' }
                        ],
                    }
                ],
            }
        },
    }
};
print Data::Dumper::Dumper $config;
ok IPC::Transit::send(qname => 'tqueue', message => $config), 'sent config';


my @counts;
eval {
    local $SIG{ALRM} = sub { die "timed out\n"; };
    alarm 12;
    while(my $message = IPC::Transit::receive(qname => 'test_out')) {
        push @counts, $message;
    }
};
alarm 0;
ok $@ ne 'timed out', 'no exception';
ok scalar @counts, 'some result(s)';
ok $counts[0]->{something}, 'something is there';
ok $counts[0]->{something} eq 'cool', 'a valid result';
if(-z $errors_log) {
    ok 1, 'no errors';
} else {
    ok 0, 'errors';
    my $text = read_file $errors_log;
    print STDERR "$text\n";
}

#ask it to go away nicely
ok IPC::Transit::send(qname => 'tqueue', message => {
    '.multimodule' => {
        control => [
            {   type => 'cleanly_exit',
                exit_externals => 1,
            }
        ],
    }
}), 'sent program exit request';

sleep 6;
ok waitpid($daemon_pid, WNOHANG) == $daemon_pid, 'waitpid';
ok !kill(9, $daemon_pid), 'program exited';

App::MultiModule::Test::finish();
App::MultiModule::Test::Collector::_finish();



done_testing();
