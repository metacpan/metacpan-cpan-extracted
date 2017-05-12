package Person::ComplexAddress;
use warnings;
use strict;
use parent 'Person::Base';

sub street {
    return $_[0]->{street} if @_ == 1;
    $_[0]->{street} = $_[1];
}

sub city {
    return $_[0]->{city} if @_ == 1;
    $_[0]->{city} = $_[1];
}

sub postalcode {
    return $_[0]->{postalcode} if @_ == 1;
    $_[0]->{postalcode} = $_[1];
}

sub country {
    return $_[0]->{country} if @_ == 1;
    $_[0]->{country} = $_[1];
}
1;
