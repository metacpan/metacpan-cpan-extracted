use v5.40;
use Getopt::Long    qw[GetOptions];
use Time::HiRes     qw[time];
use Acme::Parataxis qw[:all];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Channel;
#
GetOptions( 'count=i' => \my $count, 'rounds=i' => \my $rounds, 'compare=s' => \my $compare, 'save=s' => \my $save, 'only=s@' => \my @only ) or
    die "usage: $0 [--count N] [--rounds N] [--compare FILE] [--save FILE] [--only NAME ...]\n";
$count  //= 500;
$rounds //= 5;
die "--rounds must be positive\n" if $rounds < 1;
die "--count must be positive\n"  if $count < 1;
my %workloads = (
    startup => sub {
        run( sub { } ) for 1 .. $count;
    },
    series => sub {
        run(
            sub {
                for ( 1 .. $count ) {
                    my $fiber = fiber {};
                    await($fiber);
                }
            }
        );
    },
    priority_series => sub {
        run(
            sub {
                my $first = fiber {yield};
                $first->priority(1);
                await($first);
                for ( 1 .. $count ) {
                    my $fiber = fiber {};
                    await($fiber);
                }
            }
        );
    },
    priority_parallel => sub {
        run(
            sub {
                my $first = fiber {yield};
                $first->priority(1);
                await($first);
                my @fibers = map { fiber {} } 1 .. $count;
                await($_) for @fibers;
            }
        );
    },
    parallel => sub {
        run(
            sub {
                my @fibers = map { fiber {} } 1 .. $count;
                await($_) for @fibers;
            }
        );
    },
    semaphore => sub {
        my $gate = Acme::Parataxis::Semaphore->new( count => 0 );
        my $done = Acme::Parataxis::Semaphore->new( count => 0 );
        run(
            sub {
                for ( 1 .. $count ) {
                    fiber { $gate->down; $done->up }
                }
                for ( 1 .. $count ) {
                    $gate->up;
                    $done->down;
                }
            }
        );
    },
    channel => sub {
        my $queue = Acme::Parataxis::Channel->new( capacity => 1 );
        run(
            sub {
                fiber {
                    $queue->put($_) for 1 .. $count;
                    $queue->shutdown;
                };
                $queue->get while defined $queue->get;
            }
        );
    },
    offload => sub {
        run( sub { await_core_id() for 1 .. $count } );
    },
    offload_burst => sub {
        run(
            sub {
                my @fibers = map {
                    fiber { await_core_id() }
                } 1 .. $count;
                $_->await for @fibers;
            }
        );
    },
    sleep => sub {
        run( sub { await_sleep(1) for 1 .. $count } );
    },
    cancel_sleep => sub {
        run(
            sub {
                for ( 1 .. $count ) {
                    my $token  = Acme::Parataxis::CancellationToken->new;
                    my $worker = fiber {
                        $token->register;
                        eval { await_sleep(1000) };
                        $token->unregister;
                        return;
                    };
                    yield;
                    $token->cancel;
                    eval { $worker->await };
                }
            }
        );
    },
    virtual => sub {
        run( virtual => 1, code => sub { await_sleep(1) for 1 .. $count } );
    },
    virtual_burst => sub {
        run(
            virtual => 1,
            code    => sub {
                my @fibers = map {
                    fiber { await_sleep(1) }
                } 1 .. $count;
                $_->await for @fibers;
            }
        );
    },
    maybe_yield => sub {
        Acme::Parataxis::_maybe_yield() for 1 .. ( $count * 400 );
    },
    maybe_yield_public => sub {
        maybe_yield() for 1 .. ( $count * 400 );
    },
    maybe_yield_public_enabled => sub {
        set_preempt_threshold(1_000_000_000);    # take the enabled wrapper path without actually yielding
        maybe_yield() for 1 .. ( $count * 400 );
        set_preempt_threshold(0);
    }
);
my @names = @only ? @only : qw[startup series parallel semaphore channel offload sleep cancel_sleep virtual maybe_yield maybe_yield_public];
die "unknown workload: $_\n" for grep { !exists $workloads{$_} } @names;
my %baseline;
if ( defined $compare && -f $compare ) {
    open my $fh, '<', $compare or die "open $compare: $!\n";
    while ( my $line = <$fh> ) {
        next unless $line =~ /^(\S+)\s+([0-9.]+)\s*$/;
        $baseline{$1} = $2;
    }
    close $fh;
}

sub median (@xs) {
    my @sorted = sort { $a <=> $b } @xs;
    my $mid    = int @sorted / 2;
    return @sorted % 2 ? $sorted[$mid] : ( $sorted[ $mid - 1 ] + $sorted[$mid] ) / 2;
}
my %samples;
for my $round ( 0 .. $rounds ) {
    for my $name (@names) {
        my $started = time;
        $workloads{$name}->();
        my $elapsed = time - $started;
        push @{ $samples{$name} }, $elapsed if $round;    # round 0 is an untimed warm-up
    }
    print STDERR "round $round complete\n" if $round == 0;
    print STDERR "round $round complete\n" if $round > 0;
}
my %median = map { $_ => median( @{ $samples{$_} } ) } @names;
if ( defined $save ) {
    open my $fh, '>', $save or die "open $save: $!\n";
    print {$fh} "$_\t$median{$_}\n" for @names;
    close $fh;
}
printf "%-12s %10s %10s %8s\n", qw[workload median_s baseline_s ratio];
for my $name (@names) {
    my $base = $baseline{$name};
    printf "%-12s %10.5f %10s %8s\n", $name, $median{$name}, defined $base ? sprintf( '%.5f', $base ) : '-',
        defined $base && $base > 0 ? sprintf( '%.3fx', $median{$name} / $base ) : '-';
}
