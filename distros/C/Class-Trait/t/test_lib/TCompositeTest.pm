package TCompositeTest;

use strict;
use warnings;

use Class::Trait 'base';

use Class::Trait qw(TPrintable TComparable);

our @REQUIRES = ("compositeTestRequirement");

sub compositeTest {
    my ($self) = @_;
    $self->compositeTestRequirement();
}

1;

__DATA__
