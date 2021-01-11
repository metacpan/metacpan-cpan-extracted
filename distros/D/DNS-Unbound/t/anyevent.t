#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

for my $mod ( qw( AnyEvent ) ) {
    eval "require $mod" or plan skip_all => "No $mod: $@";
}

use Data::Dumper;
$Data::Dumper::Useqq = 1;

use_ok('DNS::Unbound::AnyEvent');

my $name = 'example.com';

my $cv = AnyEvent->condvar();

DNS::Unbound::AnyEvent->new()->resolve_async($name, 'NS')->then(
    sub {
        my ($result) = @_;

        isa_ok( $result, 'DNS::Unbound::Result', 'promise resolution' );

        diag explain [ passed => $result ];
    },
    sub {
        my $why = shift;
        fail $why;
    },
)->finally($cv);

$cv->recv();

done_testing();
