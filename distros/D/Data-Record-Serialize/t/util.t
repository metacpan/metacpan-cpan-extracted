#! perl

use Test2::V0;

use Data::Record::Serialize::Util qw( populate_set );

my $values = [qw( a b c d )];

my @tests = (
    [ 'empty specification',              [],                  [] ],
    [ 'plain values preserve order',      [qw( c a b )],       [qw( c a b )] ],
    [ 'duplicate values are discarded',   [qw( b a b +a +c )], [qw( b a c )] ],
    [ 'initial removal starts with all',  [qw( -b -d )],       [qw( a c )] ],
    [ 'initial plus loads all',           [qw( + -b )],        [qw( a c d )] ],
    [ 'initial minus starts empty',       [qw( - +b )],        [qw( b )] ],
    [ 'bare plus resets to all',          [qw( c + -b )],      [qw( a c d )] ],
    [ 'bare minus clears the set',        [qw( -b - +d +a )],  [qw( d a )] ],
    [ 'removed value can be re-appended', [qw( a b c -b +b )], [qw( a c b )] ],
);

for my $test ( @tests ) {
    my ( $label, $input, $expected ) = @{$test};
    is( populate_set( $values, $input ), $expected, $label );
}

done_testing;
