use strict;
use warnings;
use utf8;
use Test::More;
use Array::PrintCols::EastAsian;

my @array = qw/ GSX1300Rハヤブサ CBR1000RR /;

subtest 'default format' => sub {
    my $got = format_cols( \@array );
    my @expected = ( 'GSX1300Rハヤブサ', 'CBR1000RR       ' );
    is_deeply( $got, \@expected );
};

done_testing;

