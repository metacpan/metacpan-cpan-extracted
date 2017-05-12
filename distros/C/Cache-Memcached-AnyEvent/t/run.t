use strict;
use Test::More;
use Test::Memcached;
use Module::Runtime;
use constant HAVE_KETAMA => eval { require Algorithm::ConsistentHash::Ketama } || 0;
use constant HAVE_JSON => 
    eval { require JSON } ||
    eval { require JSON::XS } ||
    eval { require JSON::PP } || 0;
use constant HAVE_MESSAGE_PACK => eval { require Data::MessagePack } || 0;

my @memd;
if ( ! $ENV{PERL_ANYEVENT_MEMCACHED_SERVERS}) {
    my $port;
    for (1..5) {
        my $memd = Test::Memcached->new(base_dir => 't', options => { verbose => 1 });
            
        if (! $memd) {
            plan skip_all => "Failed to start memcached server";
        }
        if ($port) {
            $memd->start( tcp_port => $port );
        } else {
            $memd->start();
        }

        if ($port) {
            $port++;
        } else {
            $port = $memd->option('tcp_port') + 1;
        }

        # give it a second for the server to start
        push @memd, $memd;
    }

    $ENV{PERL_ANYEVENT_MEMCACHED_SERVERS} = join(',', 
        map { sprintf('127.0.0.1:%d', $_->option('tcp_port')) } @memd
    );
}

my @protocols   = qw(Text Binary);
my @selectors   = qw(Traditional Ketama);
my @serializers = qw(Storable JSON MessagePack);
my @tests     = qw(
    t::CMAETest::Commands
    t::CMAETest::ConnectFail
    t::CMAETest::CV
    t::CMAETest::Dorman
    t::CMAETest::Stats
    t::CMAETest::Consistency
);

my %HAVE_SELECTORS = (
    Traditional => 1,
    Ketama      => HAVE_KETAMA,
);
my %HAVE_SERIALIZERS = (
    Storable    => 1,
    JSON        => HAVE_JSON,
    MessagePack => HAVE_MESSAGE_PACK,
);

foreach my $protocol (@protocols) {
    foreach my $selector (@selectors) {
        foreach my $serializer (@serializers) {
            foreach my $pkg (@tests) {
                note "running $pkg test [$protocol/$selector/$serializer]";
                Module::Runtime::require_module($pkg);
                subtest "$pkg [$protocol/$selector]" => sub {
                    SKIP: {
                        if (! $HAVE_SELECTORS{ $selector }) {
                            skip("Test $pkg [$protocol/$selector/$serializer] skipped (selector $selector not available)", 1);
                        }
                        if (! $HAVE_SERIALIZERS{ $serializer }) {
                            skip("Test $pkg [$protocol/$selector/$serializer] skipped (serializer $serializer not available)", 1);
                        }
                        
                        if ( ! $pkg->should_run) {
                            skip("Test $pkg [$protocol/$selector/$serializer] skipped", 1);
                        }
                        $pkg->run( $protocol, $selector, $serializer );
                    };
                };
            }
        }
    }
}

done_testing();
