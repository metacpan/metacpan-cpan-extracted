package Extra::TSpouse;

use strict;
use warnings;

use Class::Trait 'base';
use Class::Trait 'Original::TSpouse'; # conflicts: explode

our @REQUIRES = 'lawyer';

sub explode {
    "Extra spouse explodes";
}

1;
