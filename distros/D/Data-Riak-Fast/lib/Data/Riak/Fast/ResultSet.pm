package Data::Riak::Fast::ResultSet;

use strict;
use warnings;

use Mouse;

has results => (
    is => 'rw',
    isa => 'ArrayRef[Data::Riak::Fast::Result]',
    required => 1
);

sub first { (shift)->results->[0] }

sub all { @{ (shift)->results } }

__PACKAGE__->meta->make_immutable;
no Mouse;

1;

__END__
