package Data::Riak::Fast::Role::HasRiak;

use strict;
use warnings;

use Mouse::Role;

use Data::Riak::Fast;

has riak => (
    is => 'ro',
    isa => 'Data::Riak::Fast',
    required => 1
);

no Mouse::Role;

1;

__END__
