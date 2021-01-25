package BoardStreams::Util;

use Mojo::Base -strict, -signatures;

use Mojo::JSON qw/ true false /;
use Scalar::Util 'refaddr';
use List::Util 'any';

use Exporter 'import';
our @EXPORT_OK = qw/
    true false to_bool eqq belongs_to string
/;
our %EXPORT_TAGS = (
    bool => [qw/ true false to_bool /],
);

sub to_bool :prototype(_) ($x) { $x ? true : false }

sub eqq ($x, $y) {
    return !defined $y unless defined $x;
    return !!0 unless defined $y;
    return !!0 unless ref $x eq ref $y;
    length(ref $x) ? refaddr $x == refaddr $y : $x eq $y;
}

sub belongs_to ($item, $array) {
    return any {eqq($_, $item)} @$array;
}

sub string :prototype(_) {
    return ''.($_[0] // '');
}

1;