#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

diag( "Testing AnyEvent::Promise $AnyEvent::Promise::VERSION, Perl $], $^X" );

BEGIN {
    use_ok('AnyEvent::Promise');
}

BEGIN {
    use AnyEvent::Promise qw/promise/;

    my $p = promise(sub {});
    ok(ref($p) eq 'AnyEvent::Promise', 'Convenience function');

    my $p2 = AnyEvent::Promise->new(sub {});
    ok(ref($p2) eq 'AnyEvent::Promise', 'Constructor');
}
