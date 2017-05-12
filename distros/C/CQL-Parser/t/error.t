use strict;
use warnings;
use Test::More qw( no_plan );
use Test::Exception;

use_ok( 'CQL::Parser' );
my $parser = CQL::Parser->new();

my %tests = (
    'foo and'  => [ 27, qr/missing term/ ],
    'foo !'    => [ 19, qr/unknown first class relation/ ],
);

## TODO: should add more errors here

foreach my $test (sort keys %tests) {
    my ($code,$regexp) = @{ $tests{$test} };

    throws_ok
        { $parser->parse( $test ) }
        $regexp,
        $test;

    is $parser->parseSafe( $test ), $code, "code $code";
}

