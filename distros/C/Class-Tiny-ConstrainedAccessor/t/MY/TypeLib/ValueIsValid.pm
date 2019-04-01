#!perl
# Custom type library to test value_is_valid() code path.  This is for coverage.

package MY::TypeLib::ValueIsValid;
use 5.006;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT=qw($MediumInteger);
our $MediumInteger = 'MY::TypeLib::ValueIsValid::Constraint'->new;

# Sanity check
for($MediumInteger) {
    $_->value_is_valid(15) or die 'Unexpected validation failure';
    $_->value_is_valid(0) and die 'Unexpected validation success';
}

{
    package MY::TypeLib::ValueIsValid::Constraint;
    use Scalar::Util qw(looks_like_number);

    sub new { bless {}, shift }
    sub value_is_valid {
        shift;  # Don't need $self since we're hard-coding the constraint
        looks_like_number($_[0]) && $_[0] >= 10 and $_[0] < 20
    }
} # Constraint

1;
