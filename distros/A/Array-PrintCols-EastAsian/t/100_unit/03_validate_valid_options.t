use strict;
use warnings;
use utf8;
use Test::More;
use Array::PrintCols::EastAsian qw/ _validate /;

my @array = qw/ GSX1300Rハヤブサ GSX1000R /;

subtest 'valid_array' => sub {
    my $got      = _validate( \@array );
    my %expected = (
        array  => \@array,
        gap    => 0,
        align  => 'left',
        encode => 'utf-8'
    );
    is_deeply( $got, \%expected );
};

subtest 'valid_gap' => sub {
    my $got = _validate( \@array, { gap => 5 } );
    my %expected = (
        array  => \@array,
        gap    => 5,
        align  => 'left',
        encode => 'utf-8'
    );
    is_deeply( $got, \%expected );
};

subtest 'valid_column' => sub {
    my $got = _validate( \@array, { column => 5 } );
    my %expected = (
        array  => \@array,
        column => 5,
        gap    => 0,
        align  => 'left',
        encode => 'utf-8'
    );
    is_deeply( $got, \%expected );
};

subtest 'valid_width' => sub {
    my $got = _validate( \@array, { width => 50 } );
    my %expected = (
        array  => \@array,
        gap    => 0,
        width  => 50,
        align  => 'left',
        encode => 'utf-8'
    );
    is_deeply( $got, \%expected );
};

subtest 'valid_align' => sub {
    my $got = _validate( \@array, { align => 'right' } );
    my %expected = (
        array  => \@array,
        gap    => 0,
        align  => 'right',
        encode => 'utf-8'
    );
    is_deeply( $got, \%expected );
};

subtest 'valid_encode' => sub {
    my $got = _validate( \@array, { encode => 'cp932' } );
    my %expected = (
        array  => \@array,
        gap    => 0,
        align  => 'left',
        encode => 'cp932'
    );
    is_deeply( $got, \%expected );
};

done_testing;

