use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PgSchema;

{
  package My::PgSchema::Base;
  use base 'DBIO::PostgreSQL::PgSchema';
  __PACKAGE__->pg_enum('status_type' => [qw(active inactive)]);
}

{
  package My::PgSchema::Extended;
  use base 'My::PgSchema::Base';
  __PACKAGE__->pg_enum('role_type' => [qw(admin user)]);
}

# Base class: only status_type
my $base_defs = My::PgSchema::Base->_pg_enum_defs;
is scalar @$base_defs, 1, 'base has 1 enum def';
is $base_defs->[0][0], 'status_type', 'correct name';

# Subclass: should have ONLY role_type (its own, not cumulative from parent)
my $ext_defs = My::PgSchema::Extended->_pg_enum_defs;
is scalar @$ext_defs, 1, 'subclass has its own 1 enum def (not cumulative)';
is $ext_defs->[0][0], 'role_type', 'subclass enum name correct';

# Base still only has 1
is scalar @{ My::PgSchema::Base->_pg_enum_defs }, 1,
  'base not polluted by subclass';

done_testing;
