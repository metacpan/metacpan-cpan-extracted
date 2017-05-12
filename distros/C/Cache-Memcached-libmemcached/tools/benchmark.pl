use strict;
use Benchmark qw(cmpthese);
use Cache::Memcached;
use Cache::Memcached::Fast;
use Cache::Memcached::libmemcached;
use Memcached::libmemcached qw(MEMCACHED_BEHAVIOR_BINARY_PROTOCOL);
use Getopt::Long;

my $no_block = 0;
my $server   = '';
my %modes = (
    simple_get       => 1,
    simple_get_multi => 1,
    serialize_get    => 0,
    simple_set       => 0,
);

GetOptions(
    "no_block!" => \$no_block,
    "server=s" => \$server,
    "simple-get!"       => \$modes{simple_get},
    "simple-get_multi!" => \$modes{simple_get_multi},
    "serialize-get!"    => \$modes{serialize_get},
    "compress-get!"     => \$modes{compress_get},
    "simple-set!"       => \$modes{simple_set},
    "serialize-set!"    => \$modes{serialize_set},
    "compress-set!"     => \$modes{compress_set},
) or exit 1;

my $repetitions = shift || 50_000;

$server ||= $ENV{MEMCACHED_SERVER} || '127.0.0.1:11211';

print "Module Information:\n";
foreach my $module qw(Cache::Memcached Cache::Memcached::Fast Cache::Memcached::libmemcached Memcached::libmemcached) {
    no strict 'refs';
    print " + $module => " . ${ "${module}::VERSION" }, "\n";
}

print "\n";
print "Server Information:\n";
{
    my $memd = Cache::Memcached::Fast->new({servers => [$server]});
    my $versions = $memd->server_versions;
    while (my ($server, $version) = each %$versions) {
        print " + $server => $version\n";
    }
}

print "\n";
print "Options:\n";
print " + Memcached server: $server\n";
print " + Include no block mode (where applicable)? :", $no_block ? "YES" : "NO", "\n";

my %args = (
    servers => [ $server ],
    compress_threshold => 1_000,
);

my $data;

print "\n";
print "Prepping clients...\n";
my %clients = (
    perl_memcached  => Cache::Memcached->new(\%args),
    memcached_fast  => Cache::Memcached::Fast->new(\%args),
    libmemcached    => Cache::Memcached::libmemcached->new(\%args),
    memcached_plain => do {
        my $memd = Memcached::libmemcached->new();
        if ($server =~ /^([^:]+):([^:]+)$/) {
            $memd->memcached_server_add($1, $2);
        } else {
            $memd->memcached_server_add_unix_socket($server);
        }
        $memd;
    },
);

if (0) {
    $clients{libmemcached_binary} =
        Cache::Memcached::libmemcached->new({ %args, binary_protocol => 1 });

    $clients{memcached_plain_binary} = do {
        my $memd = Memcached::libmemcached->new();
        if ($server =~ /^([^:]+):([^:]+)$/) {
            $memd->memcached_server_add($1, $2);
        } else {
            $memd->memcached_server_add_unix_socket($server);
        }
        $memd->memcached_behavior_set( MEMCACHED_BEHAVIOR_BINARY_PROTOCOL, 1 );
        $memd;
    };
}

# Include non-blocking client modes
if ($no_block) {
    $clients{libmemcached_no_block} = Cache::Memcached::libmemcached->new({
        %args, no_block => 1
    });
}

print "\n";

if ($modes{simple_get}) {
    print qq|==== Benchmark "Simple get() (scalar)" ====\n|;
    $data = '0123456789' x 10;
    $clients{perl_memcached}->set( 'foo', $data );
    cmpthese($repetitions, +{
        map {
            my $client = $clients{$_};
            ($_ => sub { 
                my $value  = ref $client eq 'Memcached::libmemcached' ?
                    $client->memcached_get('foo') :
                    $client->get('foo');
                die "$client did not return proper value (wanted '$data', got '$value')"
                    if $value ne $data;
            })
        } keys %clients
    });
}

if ($modes{simple_get_multi}) {
    print qq|==== Benchmark "Simple get_multi() (scalar)" ====\n|;

    my @keys = ('a'..'z');
    for (@keys) {
        $clients{perl_memcached}->set($_, $_);
    }
    cmpthese($repetitions, +{
        map {
            my $client = $clients{$_};
            $_ => sub { $client->get_multi(@keys) }
        } keys %clients
    });
}

if ($modes{serialize_get}) {
    print qq|==== Benchmark "Serialization with get()" ====\n|;
    $data = { foo => [ qw(1 2 3) ] };
    $clients{perl_memcached}->set( 'foo', $data );
    cmpthese($repetitions, {
        map {
            my $client = $clients{$_};
            $_ => sub { 
                my $h = $client->get('foo');
                ref($h) eq 'HASH' or die "$client did not return a hash";
                ref($h->{foo}) eq 'ARRAY' or die "$client did not return an array in hash";
            }
        } keys %clients
    });
}

if ($modes{compress_get}) {
    print qq|==== Benchmark "Simple get() (w/compression)" ====\n|;
    $data = '0123456789' x 500;
    $clients{perl_memcached}->set( 'foo', $data );
    cmpthese($repetitions, {
        map {
            my $client = $clients{$_};
            $_ => sub { 
                my $h = $client->get('foo');
                length($h) == 5000 or die "$client did not return 5000 bytes";
            }
        } keys %clients
    });
}

if ($modes{simple_set}) {
    print qq|==== Benchmark "Simple set() (scalar)" ====\n|;
    $data = '0123456789' x 10;
    cmpthese($repetitions, {
        map {
            my $client = $clients{$_};
            $_ => sub { 
                $client->set('foo', $data);
            }
        } keys %clients
    });
}

if ($modes{serialize_set}) {
    print qq|==== Benchmark "Simple set() (w/seriale)" ====\n|;
    $data = { foo => [ qw( 1 2 3 ) ] };
    cmpthese($repetitions, {
        map {
            my $client = $clients{$_};
            $_ => sub { 
                $client->set('foo', $data);
            }
        } keys %clients
    });
}

if ($modes{compress_set}) {
    print qq|==== Benchmark "Simple set() (w/compress)" ====\n|;
    $data = '0123456789' x 500;
    cmpthese($repetitions, {
        map {
            my $client = $clients{$_};
            $_ => sub { 
                $client->set('foo', $data);
            }
        } keys %clients
    });
}

__END__

{
    print qq|==== Benchmark "Simple set() (w/serialize)" ====\n|;
    $data = { foo => [ qw(1 2 3) ] };
    cmpthese(100_000, {
        perl_memcahed => sub {
            $memd->set( 'foo', $data );
        },
        memcached_fast => sub {
            $memd_fast->set( 'foo', $data );
        },
        libmemcached  => sub {
            $libmemd->set( 'foo', $data );
        },
#        libmemcached_no_block  => sub {
#            $libmemd_no_block->set( 'foo', $data );
#        },
    });
}

{
    print qq|==== Benchmark "Simple set() (w/compress)" ====\n|;
    $data = '0123456789' x 500;
    cmpthese(100_000, {
        perl_memcahed => sub {
            $memd->set( 'foo', $data );
        },
        memcached_fast => sub {
            $memd_fast->set( 'foo', $data );
        },
        libmemcached  => sub {
            $libmemd->set( 'foo', $data );
        },
#        libmemcached_no_block  => sub {
#            $libmemd_no_block->set( 'foo', $data );
#        },
    });
}



