#!perl

use Test::Most;
use DateTime;
use Business::BR::Boleto::Utils qw{ fator_vencimento };

my ( @tests, $mod );

@tests = (
    {
        input    => DateTime->new( year => 1997, month => 10, day => 7 ),
        expected => 0,
        name     => 'DDF of base date is 0',
    },
    {
        input    => DateTime->new( year => 2025, month => 2, day => 21 ),
        expected => 9999,
        name     => 'Max DDF is on 2025-02-21',
    },
    {
        input    => DateTime->new( year => 1997, month => 11, day => 7 ),
        expected => 31,
        name => 'DDF for one month after base date is 31',
    },
    {
        input    => DateTime->new( year => 2014, month => 5, day => 5 ),
        expected => 6054,
        name => 'DDF for 2014-05-05 is 6054',
    },
    {
        input    => DateTime->new( year => 2014, month => 6, day => 5 ),
        expected => 6085,
        name => 'DDF for 2014-06-05 is 6085',
    },
    {
        input    => DateTime->new( year => 2014, month => 7, day => 5 ),
        expected => 6115,
        name => 'DDF for 2014-07-05 is 6115',
    },
);

foreach my $test (@tests) {
    is fator_vencimento( $test->{input} ), $test->{expected}, $test->{name};
}

done_testing;
