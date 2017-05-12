use strict;
use warnings;
use 5.008_001;

use Test::More 0.98;

use App::Memcached::CLI::Main;
use App::Memcached::CLI::Constants ':all';
use App::Memcached::CLI::Util ':all';

my $Class = 'App::Memcached::CLI::Main';

subtest 'With address:port' => sub {
    my @patterns = (
        [qw/127.0.0.1:11211/],
        [qw/www.google.com:443/],
    );
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        is($parsed->{addr}, $ptn->[0], 'addr='.$ptn->[0]);
    }
};

subtest 'With host' => sub {
    my @patterns = (
        [qw/192.168.0.1/],
        [qw/www.google.com/],
    );
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        is(
            $parsed->{addr},
            $ptn->[0].':'.DEFAULT_PORT(),
            'addr='.$ptn->[0].':(default-port)',
        );
    }
};

subtest 'With addr by option' => sub {
    my @patterns = (
        [qw/-a 192.168.0.1/],
        [qw/--addr www.google.com:1986/],
    );
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        my $addr_to_be = create_addr($ptn->[1]);
        is($parsed->{addr}, $addr_to_be, '--addr='.$addr_to_be);
    }
};

done_testing;

