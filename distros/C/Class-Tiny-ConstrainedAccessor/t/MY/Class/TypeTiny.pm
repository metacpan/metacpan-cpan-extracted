#!perl
package MY::Class::TypeTiny;
use 5.006;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use Type::Tiny;

my $MediumInteger;
BEGIN {
    $MediumInteger = Type::Tiny->new(
        name => 'MediumInteger',
        constraint => sub { looks_like_number($_) and $_ >= 10 and $_ < 20 }
    );

    # Sanity check
    my $av = eval { $MediumInteger->can('assert_valid') };
    die "cannot assert_valid: $@" unless $av;
}

use Class::Tiny::ConstrainedAccessor
    medint => $MediumInteger,           # create accessor sub medint()
    med_with_default => $MediumInteger,
    lazy_default => $MediumInteger,
;

# After using ConstrainedAccessor
use Class::Tiny qw(medint regular), {
    med_with_default => 12,
    lazy_default => sub { 19 },
};

1;
