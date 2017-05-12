package My::Schema::ResultSet::Person;

use strict;
use warnings;
use base qw(DBIx::Class::ResultSet);

__PACKAGE__->load_components(qw(ResultSet::ParameterizedJoinHack));

1;
