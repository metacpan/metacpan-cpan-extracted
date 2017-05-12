use strict;
use warnings;
use Test::More;
use Data::Dumper;

use Cache::KyotoTycoon;

use t::Util;

test_kt(
    sub {
        my $port = shift;
        my $kt = Cache::KyotoTycoon->new(port => $port);
        my $report = $kt->report();
        unless (($report->{conf_kt_features} ||'') =~ /\(lua\)/) {
            plan skip_all => "this test requires ktserver with --enable-lua";
        }
        subtest 'myecho' => sub {
            my $input = {foo => 'bar', 'hoge' => 'fuga'};
            eval {
                my $got = $kt->play_script('myecho', $input);
                is_deeply($got, $input);
            };
            if (my $e = $@) {
                like $e, qr{501};
            }
        };
        done_testing;
    },
    sub {
        my ($port, $ktserver) = @_;
        exec $ktserver, '-port', $port, '-scr', 't/myecho.lua';
        die "cannot exec ktserver";
    },
);


