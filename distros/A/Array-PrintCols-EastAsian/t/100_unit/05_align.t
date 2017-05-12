use strict;
use warnings;
use utf8;
use Test::More;
use Array::PrintCols::EastAsian qw/ _align /;

my @array = qw/ GSX1300Rハヤブサ CBR1000RR /;

subtest 'align left' => sub {
    my $got = _align( { array => \@array, align => 'left' } );
    my @expected = ( 'GSX1300Rハヤブサ', 'CBR1000RR       ' );
    is_deeply( $got, \@expected );
};

subtest 'align center' => sub {
    my $got = _align( { array => \@array, align => 'center' } );
    my @expected = ( 'GSX1300Rハヤブサ', '   CBR1000RR    ' );
    is_deeply( $got, \@expected );
};

subtest 'align right' => sub {
    my $got = _align( { array => \@array, align => 'right' } );
    my @expected = ( 'GSX1300Rハヤブサ', '       CBR1000RR' );
    is_deeply( $got, \@expected );
};

done_testing;

