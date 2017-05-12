use strict;
use warnings;
use Test::More;
use Test::TCP;
use File::Which;
use Cache::KyotoTycoon::REST;
use HTTP::Date qw/str2time/;

my $ktserver = which('ktserver');
plan skip_all => 'ktserver is required for this test' unless $ktserver;

test_tcp(
    client => sub {
        my $port = shift;

        my $key = "hoge" . rand();
        my $rest = Cache::KyotoTycoon::REST->new(port => $port);

        is $rest->base, "http://127.0.0.1:$port/", 'base';

        subtest 'PUT' => sub {
            $rest->put($key, "fuga1", 100);
            ok 1;
        };

        subtest 'GET' => sub {
            is scalar($rest->get("UNKNOWN KEY!")), undef;

            is scalar($rest->get($key)), "fuga1";
        };

        subtest 'HEAD' => sub {
            my $expires = $rest->head($key);
            ok $expires;
            cmp_ok abs(str2time($expires)-time()-100), '<', 10;

            is($rest->head("UNKNOWNNNNNNN"), undef);
        };

        subtest 'DELETE' => sub {
            is $rest->delete($key), 1, 'remove.';
            is $rest->delete($key), 0, 'removed. not found.';
        };
    },
    server => sub {
        my $port = shift;
        exec $ktserver, '-port', $port;
        die "cannot execute";
    },
);

done_testing;
