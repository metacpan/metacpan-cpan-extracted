#!perl
package MY::Class::TypeNano;
use 5.006;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use Type::Nano;

use vars::i '$MediumInteger' => Type::Nano->new(
        name => 'MediumInteger',
        constraint => sub { looks_like_number($_) and $_ >= 10 and $_ < 20 }
    );

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

# Sanity check
my $av = eval { $MediumInteger->can('check') };
die "cannot check: $@" unless $av;

1;
