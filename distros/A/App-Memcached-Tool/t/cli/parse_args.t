use strict;
use warnings;
use 5.008_001;

use Test::More 0.98;

use App::Memcached::Tool::CLI;
use App::Memcached::Tool::Constants ':all';
use App::Memcached::Tool::Util ':all';

my $Class = 'App::Memcached::Tool::CLI';

subtest 'With no argument' => sub {
    my $default = 'display';
    local @ARGV = ();
    my $parsed = $Class->parse_args;
    is($parsed->{mode}, $default, "default $default");
};

subtest 'With normal single mode' => sub {
    my @pattern = qw/dump/;
    local @ARGV = @pattern;
    my $parsed = $Class->parse_args;
    is($parsed->{mode}, $pattern[0], 'mode='.$pattern[0]);
    is($parsed->{addr}, DEFAULT_ADDR(), 'addr=(default)');
};

subtest 'With address:port and mode' => sub {
    my @patterns = (
        [qw/127.0.0.1:11211 display/],
        [qw/www.google.com:443 stats/],
    );
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        is($parsed->{mode}, $ptn->[1], 'mode='.$ptn->[1]);
        is($parsed->{addr}, $ptn->[0], 'addr='.$ptn->[0]);
    }
};

subtest 'With host and mode' => sub {
    my @patterns = (
        [qw/192.168.0.1 display/],
        [qw/www.google.com stats/],
    );
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        is($parsed->{mode}, $ptn->[1], 'mode='.$ptn->[1]);
        is(
            $parsed->{addr},
            $ptn->[0].':'.DEFAULT_PORT(),
            'addr='.$ptn->[0].':(default-port)',
        );
    }
};

subtest 'With addr and mode by option' => sub {
    my @patterns = (
        [qw/-a 192.168.0.1 -m stats/],
        [qw/--addr www.google.com:1986 --mode settings/],
    );
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        is($parsed->{mode}, $ptn->[3], '--mode='.$ptn->[3]);
        my $addr_to_be = create_addr($ptn->[1]);
        is($parsed->{addr}, $addr_to_be, '--addr='.$addr_to_be);
    }
};

subtest 'With help/-h/--help' => sub {
    my @patterns = ([qw/help/], [qw/-h/], [qw/--help/]);
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        is($parsed->{mode}, 'help', $ptn->[0]);
    }
};

subtest 'With man/--man' => sub {
    my @patterns = ([qw/man/], [qw/--man/]);
    for my $ptn (@patterns) {
        local @ARGV = @$ptn;
        my $parsed = $Class->parse_args;
        is($parsed->{mode}, 'man', $ptn->[0]);
    }
};

subtest '--help/--man overwrites other modes' => sub {
    my @patterns = ([qw/display --help help/], [qw/stats --man man/]);
    for my $ptn (@patterns) {
        local @ARGV = @$ptn[0,1];
        my $parsed = $Class->parse_args;
        is($parsed->{mode}, $ptn->[2], "$ptn->[0] is overwritten by $ptn->[1]");
    }
};

done_testing;

