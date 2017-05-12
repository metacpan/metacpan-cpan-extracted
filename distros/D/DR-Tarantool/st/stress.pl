#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open qw(:std :utf8);

use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);
use lib qw(st);
use Coro;
use DR::Tarantool::StartTest;
use DR::Tarantool;
use Carp;
use File::Spec::Functions 'catfile', 'rel2abs';
use File::Basename 'dirname', 'basename';
use POSIX;
use UUID;
use Scalar::Util;
use FindBin;
use Coro::AnyEvent;
use AnyEvent;
use Encode qw(decode_utf8);
use feature 'state';
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;



our $tarantool;
our $errors = 0;
my $verbose;

sub cfg($) {
    state $cfg;
    state %cache;
    unless ($cfg) {
        my $name = rel2abs catfile $FindBin::Bin, 'stress.cfg';
        die "File $name is not found\n" unless -r $name;
        $cfg = do $name;
        die if $@;
    }
    
    my $path = shift;
    return $cache{$path} if exists $cache{$path};
    my @spath = split /\./, $path;
    my $o = $cfg;
    for (@spath) {
        croak "Path $path is not found in config file" unless exists $o->{ $_ };
        $o = $o->{ $_ };
    }

    return $cache{$path} = $o;
}

sub df($;@) {
    return unless $verbose;
    my ($fmt, @args) = @_;
    $fmt =~ s/\s*$/\n/;

    unshift @args => $$;
    unshift @args => POSIX::strftime '%d/%m %H:%M:%S' => localtime;
    return printf '%s (%s) ' . $fmt, @args;
}

sub uuid() {
    UUID::generate my $uuid;
    $uuid =~ s/./sprintf '%02x', ord $&/ge;
    return $uuid;
}

sub tnt() {
    state (@process, $tnt);

    unless($tnt) {
        if (@process) {
            push @process => $Coro::current;
            Coro::schedule;

        } else {
            push @process => $Coro::current;
            $tnt = coro_tarantool
                    host        => '127.0.0.1',
                    port        => $tarantool->primary_port,
                    spaces => {
                        0 => {
                            name            => 'one_hash',
                            default_type    => 'STR',
                            fields  => [
                                'id',
                                'value',
                            ],
                            indexes => {
                                0 => {
                                    name    => 'id',
                                    fields  => [ 'id' ],
                                }
                            }
                        },
                        1 => {
                            name            => 'one_tree',
                            default_type    => 'STR',
                            fields  => [
                                'id',
                                'value',
                            ],
                            indexes => {
                                0 => {
                                    name    => 'id',
                                    fields  => [ 'id' ],
                                }
                            }
                        },
                        
                        5   => {
                            name            => 'orders',
                            default_type    => 'UTF8STR',
                            fields          => [
                                'oid',
                                'pid',
                                'oid_in_pid',
                                'time',
                                'status',
                                'sid',
                                'did',
                                'rating',
                                'feedback',
                                'driver_xml',
                                'xml',
                            ],
                            indexes => {
                                0   => {
                                    name    => 'oid',
                                    fields  => 'oid',
                                },
                                1   => {
                                    name    => 'parent',
                                    fields  => [ 'pid', 'oid_in_pid' ],
                                },
                                2   => {
                                    name    => 'time',
                                    fields  => 'time'
                                },
                                3   => {
                                    name    => 'status',
                                    fields  => [ 'status', 'sid' ]
                                },
                                4   => {
                                    name    => 'driver',
                                    fields  => [ 'did', 'status' ]
                                },
                            }
                        },

                    }

            ;

            while(my $coro = shift @process) {
                next if $coro == $Coro::current;
                $coro->ready;
            }
        }

    }
    return $tnt;
}

sub error($$;@) {
    my ($cond, $name, @args) = @_;
    return $cond unless $cond;
    $errors++;
    df 'Error ' . $name, @args;
    return $cond;
}



pod2usage() unless GetOptions
    'help|h'        => \my $help,
    'verbose|v'     => \$verbose,
    'timeout|t=i'   => \my $timeout,
    'forks|f=i'     => \my $forks,
;

pod2usage(-verbose => 2) if $help;
$timeout ||= 120;

my $primary_pid = $$;

{
    my $cfg = rel2abs catfile $FindBin::Bin, 'stress.tarantool.cfg';
    $tarantool = DR::Tarantool::StartTest->run(
        cfg         => $cfg,
        script_dir  => rel2abs $FindBin::Bin,
    );
    unless ($tarantool->started) {
        df "Can't start tarantool\n%s", $tarantool->log;
        exit -1;
    }
}

my @child;

df 'Started main process %s', $primary_pid;

$SIG{CHLD} = 'none';

for (1 .. $forks // cfg 'forks') {
    my $pid = fork;
    unless ($pid) {
        @child = ();
        last;
    }
    push @child => $pid;
}


my $coro = $Coro::current;

$SIG{INT} = $SIG{TERM} = $SIG{__DIE__} = sub {
    if ($$ == $primary_pid) {
        $tarantool->kill('KILL') if $tarantool;
        df 'Exit loop';
        df '%s', $tarantool->log if $tarantool;
        kill TERM => $_ for @child;
    }
    error 1, 'Signal or exception was caught';
    $coro->ready;
    $coro->cede_to;
};


my @checks = glob catfile 'st', 'Check', '*.pm';
die "Can't find any check in st/Check" unless @checks;

for (@checks) {
    my $cname = basename $_ => '.pm';
    my $name = "Check::$cname";

    df 'try to init module %s', $name;

    unless (cfg sprintf 'check.%s.enabled', lc $cname) {
        df ' -- %s is disabled by config, skipping...', $cname;
        next;
    }

    {
        no strict 'refs';
        if (cfg sprintf 'check.%s.verbose', lc $cname) {
            *{ $name . '::df' } = sub ($;@) {
                my $fmt = shift;
                $fmt = "$cname: $fmt";
                unshift @_ => $fmt;
                goto \&df;
            };
        } else {
            *{ $name . '::df' } = sub {  };
        }

        *{ $name . '::error' } = sub {
            my ($cond, $name, @args) = @_;
            return error $cond, "%s $name", $cname, @args;
        };

        *{ $name . '::uuid' } = \&uuid;
        *{ $name . '::tnt' } = \&tnt;
        *{ $name . '::cfg' } = \&cfg;
        *{ $name . '::now' } = \&AnyEvent::now;
    }
    
    eval "require $name;";
    die if $@;
    
    die "There is no finction $name\->start" unless $name->can('start');

    df "starting check process $name\->start";
    async {
        eval { $name->start($tarantool, $primary_pid) };
        df 'Unexpected process "%s" shutdown: %s',
            $name, decode_utf8($@ // 'no errors');
        kill INT => $$;
    };
}

async {
    Coro::AnyEvent::sleep $timeout;
    $coro->ready;
};

Coro::schedule;

for (@child) {
    waitpid $_, 0;
    error $?, 'Child %s returns non-zero code: %s', $_, $?;
}

$tarantool->kill('KILL') if $$ ~~ $primary_pid;

df 'There were %s errors total', $errors;
exit($errors && 1);


=head1 NAME

stress.pl - stress test for L<tarantool|http://tarantool.org>

=head1 SYNOPSIS

perl stress.pl [ OPTIONS ]

=head2 OPTIONS

=over

=item -h | --help

Display helpscreen

=item -v | --verbose

Enable verbose while running

=item -t | --timeout SECONDS

How long the test must be started. Default: 120 seconds.

=back

=cut
