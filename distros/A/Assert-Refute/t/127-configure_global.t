#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 2;

require Assert::Refute;

my $cb = sub { };

Assert::Refute->configure_global( { on_pass => $cb, on_fail => $cb } );

subtest "empty package" => sub {
    my $conf = do {
        package Foo;
        Assert::Refute->get_config;
    };
    is +$conf->{on_pass}, $cb, "callback unchanged";
};

subtest "redefine on_fail" => sub {
    my $conf = do {
        package Foo;
        Assert::Refute->configure( { on_fail => 'croak' } );
        Assert::Refute->get_config;
    };
    is +$conf->{on_pass}, $cb, "callback unchanged";
    isnt +$conf->{on_fail}, $cb, "callback redefined";
};
