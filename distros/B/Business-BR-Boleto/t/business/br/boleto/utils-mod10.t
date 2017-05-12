#!perl

use Test::Most;
use Business::BR::Boleto::Utils qw{ mod10 };

my @tests;

@tests = (
    {
        input    => undef,
        expected => 0,
        name     => 'mod10( undef ) is 0',
    },
    {
        input    => 261533,
        expected => 4,
        name     => 'mod10( 261533 ) is 4',
    },
    {
        input    => ' 0123 006789-6',
        expected => 3,
        name     => 'mod10(" 0123 006789-6") is 3',
    },
);

foreach my $test (@tests) {
    is mod10( $test->{input} ), $test->{expected}, $test->{name};
}

done_testing;
