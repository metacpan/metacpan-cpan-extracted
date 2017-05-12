use strict;
use blib;
use Cache::Memcached;
use Cache::Memcached::AnyEvent;
use Data::Dumper;
use Benchmark qw(cmpthese);
use Test::More;

print <<EOM;

Cache::Memcached::AnyEvent Benchmark
------------------------------------

1) You should always run this benchmark with MULTIPLE memcached servers.
   Event-driven tools always work best when there are multiple I/O channels
   to multiplex with.

2) Your servers should be specified in MEMCACHED_SERVERS environment variable.
   Multiple server names should be separated by comma. If the variable is not
   set, Test::Memcached will start 5 servers on ports that it can find.

EOM

my @guards;
my @servers;
if ($ENV{MEMCACHED_SERVERS}) {
    @servers = split /,/, $ENV{MEMCACHED_SERVERS};
} else {
    require Test::Memcached;
    for (1..5) {
        my $memd = Test::Memcached->new();
        $memd->start();
        push @guards, $memd;
        push @servers, join(':', '127.0.0.1', $memd->option('tcp_port') );
    }
}

my @keys = ('a'..'z');

my %args = (
    servers => \@servers,
    namespace => join('.', time(), $$, rand(), '')
);

my %datasets; %datasets = (
    memd => {
        name => 'Cache::Memcached',
        object => Cache::Memcached->new(\%args),
        version => $Cache::Memcached::VERSION,
    },
    memd_anyevent => {
        name => 'Cache::Memcached::AnyEvent',
        object => Cache::Memcached::AnyEvent->new(\%args),
        version => $Cache::Memcached::AnyEvent::VERSION,
    },
    memd_anyevent_bin => {
        name => 'Cache::Memcached::AnyEvent (Binary)',
        object => Cache::Memcached::AnyEvent->new({
            %args,
            protocol_class => 'Binary',
        }),
        version => $Cache::Memcached::AnyEvent::VERSION,
    },
);

my %runs = (
    memd          => sub {
        my $memd = $datasets{memd}->{object};
        my @mykeys = map { join( '_', "memd", $_ ) } @keys;
        for (1..100) {
            my $values = $memd->get_multi(@mykeys);
            verify_values("memd", $values);
        }
    },
    memd_anyevent => sub {
        my $cv = AE::cv;
        my $memd = $datasets{memd_anyevent}->{object};
        my @mykeys =  map { "memd_anyevent_${_}" } @keys;
        for (1..100) {
            $cv->begin;
            $memd->get_multi(\@mykeys, sub {
                my $values = shift;
                verify_values("memd_anyevent", $values);
                $cv->end;
            } );
        }
        $cv->recv;
    },
    memd_anyevent_bin => sub {
        my $cv = AE::cv;
        my $memd = $datasets{memd_anyevent_bin}->{object};
        my @mykeys = map { "memd_anyevent_bin_${_}" } @keys;
        for (1..100) {
            $cv->begin;
            $memd->get_multi(\@mykeys, sub {
                my $values = shift;
                verify_values("memd_anyevent_bin", $values);
                $cv->end;
            } );
        }
        $cv->recv;
    },
);

# used to verify that we have all the values.
sub verify_values {
    my ($type, $values) = @_;
    is_deeply( [ map { join('_', $type, $_) } @keys ], [ sort keys %$values ],
        "[$type] got back the correct keys" );
    is_deeply( $values, $datasets{$type}->{values}, "[$type] got back the correct value" );
}

if ( eval { require Cache::Memcached::Fast } && !$@ ) {
    $datasets{memd_fast} = {
        name => 'Cache::Memcached::Fast',
        object => Cache::Memcached::Fast->new(\%args),
        version => $Cache::Memcached::Fast::VERSION
    };
    $runs{memd_fast} = sub {
        my $memd = $datasets{memd_fast}->{object};
        my @mykeys = map { join( '_', "memd_fast", $_ ) } @keys;
        for (1..100) {
            my $values = $memd->get_multi(@mykeys);
            verify_values("memd_fast", $values);
        }
    };
}

if ( eval { require Algorithm::ConsistentHash::Ketama } && !$@ ) {
    $datasets{memd_anyevent_ketama} = {
        name => 'Cache::Memcached::AnyEvent (Ketama)',
        object => Cache::Memcached::AnyEvent->new({
            %args,
            selector_class => 'Ketama'
        }),
        version => $Cache::Memcached::AnyEvent::VERSION,
    };
    $runs{memd_anyevent_ketama} = sub {
        my $cv = AE::cv;
        my $memd = $datasets{memd_anyevent_ketama}->{object};
        my @mykeys = map { "memd_anyevent_ketama_${_}" } @keys;
        for (1..100) {
            $cv->begin;
            $memd->get_multi(\@mykeys, sub {
                my $values = shift;
                verify_values("memd_anyevent_ketama", $values);
                $cv->end;
            } );
        }
        $cv->recv;
    },
}

if ( eval { require Memcached::Client } && !$@) {
    $datasets{memd_client} = {
        name => 'Memcached::Client',
        object => Memcached::Client->new(\%args),
        version => $Memcached::Client::VERSION
    };
    $datasets{memd_client_bin} = {
        name => 'Memcached::Client',
        object => Memcached::Client->new({
            %args,
            protocol_class => 'Binary',
        }),
        version => $Memcached::Client::VERSION
    };
    $runs{memd_client} = sub {
        my $cv = AE::cv;
        my $memd = $datasets{memd_client}->{object};
        my @mykeys = map { "memd_client_$_" } @keys;
        for (1..100) {
            $cv->begin;
            $memd->get_multi(\@mykeys, sub {
                my $values = shift;
                verify_values("memd_client", $values);
                $cv->end;
            } );
        }
        $cv->recv;
    };
    $runs{memd_client_bin} = sub {
        my $cv = AE::cv;
        my $memd = $datasets{memd_client}->{object};
        for (1..100) {
            $cv->begin;
            $memd->get_multi([map { "memd_client_bin_$_" } @keys ], sub {
                my $values = shift;
                $cv->end;
            } );
        }
        $cv->recv;
    };
}

print <<EOM;

Servers: @servers
EOM
foreach my $data ( values %datasets ) {
    print "$data->{name}: $data->{version}\n";
}

{ # now prep the servers
    $datasets{memd}->{object}->flush_all();
    foreach my $type (qw(memd memd_fast memd_anyevent memd_anyevent_bin memd_client memd_client_bin)) {
        foreach my $key (@keys) {
            my $fqkey = join '_', $type, $key;
            my $value = join('.', ($key) x 100);
            $datasets{$type}->{values}->{$fqkey} = $value;
            $datasets{memd}->{object}->set( $fqkey => $value );
        }
    }

    # ketama uses a different distribution, so we need to create it using our
    # client, which may look like cheating...

    my $cv = AE::cv;
    foreach my $type (qw(memd_anyevent_ketama)) {
        foreach my $key (@keys) {
            my $fqkey = join '_', $type, $key;
            my $value = join('.', ($key) x 100);
            $datasets{$type}->{values}->{$fqkey} = $value;
            $cv->begin;
            $datasets{memd_anyevent_ketama}->{object}->set( $fqkey => $value, sub { $cv->end } );
        }
    }
    $cv->recv;
}

cmpthese(10 => \%runs);

done_testing();

__END__
