use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Array::PrintCols::EastAsian qw/ _validate /;

my @array = qw/ GSX1300Rハヤブサ GSX1000R /;

subtest 'invalid_gap negative number' => sub {
    throws_ok { _validate( \@array, { gap => -5 } ); } qr/Gap option should be a integer greater than or equal 1/,
        'negative number of gap caught okay';
};

subtest 'invalid_column negative number' => sub {
    throws_ok { _validate( \@array, { column => -5 } ); } qr/Column option should be a integer greater than 0/,
        'negative number of column caught okay';
};

subtest 'invalid_column 0' => sub {
    throws_ok { _validate( \@array, { column => 0 } ); } qr/Column option should be a integer greater than 0/,
        'column 0 caught okay';
};

subtest 'invalid_width negative number' => sub {
    throws_ok { _validate( \@array, { width => -5 } ); } qr/Width option should be a integer greater than 0/,
        'negative number of width caught okay';
};

subtest 'invalid_width 0' => sub {
    throws_ok { _validate( \@array, { width => 0 } ); } qr/Width option should be a integer greater than 0/,
        'width 0 caught okay';
};

subtest 'invalid_align' => sub {
    throws_ok { _validate( \@array, { align => 'top' } ); } qr/Align option should be left, center, or right/,
        'invalid align option caught okay';
};

done_testing;

