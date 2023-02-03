#!perl -T

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Exception;

use Capture::Tiny qw(capture);
use Data::Dump::Color qw(dump dd ddx);

local $Data::Dump::Color::COLOR = 0;
local $Data::Dump::Color::COLOR_THEME = "Default16";

subtest dump => sub {
    lives_ok { my $foo = dump([1]) };

    is_deeply(dump([1, 2, 3]), "[1, 2, 3]");

    # test circular ref
    my $var = [0,1,[],3]; $var->[1] = $var->[2];
    is_deeply(dump($var), q(do {
  my $var = [0, [], '$var->[1]', 3];
  $var->[2] = $var->[1];
  $var;
}));

    # test scalar ref
    is_deeply(dump(\1), "\\1");

    # test object with scalar ref
    my $ref = \\2;
    my $obj = bless $ref, "MyClass";
    is_deeply(dump($obj), q<bless(do{\(my $o = \2)}, "MyClass")>);
};

subtest dd => sub {
    my ($stdout, $stderr, $exit);
    lives_ok {
        ($stdout, $stderr, $exit) = capture { dd [3] };
    };
    like($stdout, qr/\A\Q[3]\E/);
};

subtest ddx => sub {
    my ($stdout, $stderr, $exit);
    lives_ok {
        ($stdout, $stderr, $exit) = capture { ddx [4] };
    };
    like($stdout, qr/\Q01-basics.t\E:.*\Q[4]\E/);
};

DONE_TESTING:
done_testing;
