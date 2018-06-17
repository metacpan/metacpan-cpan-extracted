package Data::Format::Sanitize::Number 0.2;

use 5.008;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw/
    money
    money_integer
    money_decimal
    money_to_int
/;
our %EXPORT_TAGS = (
    'money' => [qw/
        money
        money_integer
        money_decimal
        money_to_int
    /]
);

use Carp q/croak/;
use POSIX q/floor/;
use Scalar::Util q/looks_like_number/;
use Data::Format::Validate::Number 'looks_like_money';
use aliased 'Data::Format::Error::ValueProvideException';
use aliased 'Data::Format::Error::ValueNumericException';

sub money {

    my $value = shift || die ValueProvideException->new->stacktrace;

    my ($integer, $decimal) = split /\./, $value;
    money_integer($integer).money_decimal($decimal);
}

sub money_integer {

    my $value = shift || die ValueProvideException->new->stacktrace;
    die ValueNumericException->new->stacktrace unless looks_like_number $value;

    $value = reverse floor($value);
    $value =~ s/(\d{3})(?!$)/$1./g;
    reverse $value;
}

sub money_decimal {

    my $value = shift;

    $value && looks_like_number $value
    ? ','.$value
    : ',00';
}

sub money_to_int {

    my $value = shift || die ValueProvideException->new->stacktrace;
    die ValueNumericException->new->stacktrace unless looks_like_money $value;

    my ($integer, $decimal) = split ',', $value;
    integer_money_to_int($integer) + decimal_money_to_int($decimal);
}

sub integer_money_to_int {

    my $value = shift;
    $value =~ s/[,\.]//g;
    $value + 0;
}

sub decimal_money_to_int {

    my $value = shift;
    ".$value" + 0;
}
1;