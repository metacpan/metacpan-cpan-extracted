use strict;
use warnings;
use Test::More;

# Offline regression for karr k30 (ADR 0043): a column WITHOUT an is_nullable
# key must deploy as NOT NULL. core's canonical_column (core k147,
# ADR 0043) reads a missing is_nullable as not_null => 1, so the compiled
# model claims NOT NULL -- install_ddl's old
# `defined $info->{is_nullable} && !$info->{is_nullable}` guard deployed such
# a column as nullable instead. The gate is now `!$info->{is_nullable}`, the
# same flip every other DDL driver in the family carries.

use_ok 'DBIO::DB2::DDL';

{
  package My::NN::Schema::Thing;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    # No is_nullable key at all: the ADR 0043 regression case.
    label    => { data_type => 'varchar', size => 64 },
    optional => { data_type => 'varchar', size => 64, is_nullable => 1 },
    required => { data_type => 'varchar', size => 64, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package My::NN::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Thing => 'My::NN::Schema::Thing');
}

my $ddl = DBIO::DB2::DDL->install_ddl('My::NN::Schema');
ok length $ddl, 'DDL generated';

# The regression itself: a column with no is_nullable key deploys as
# NOT NULL, because canonical_column reads the absence as not_null => 1.
like($ddl, qr/"label"\s+VARCHAR\(64\) NOT NULL/,
  'a column with no is_nullable key deploys as NOT NULL (ADR 0043)');

# The two deliberate sides stay put: explicit nullable stays nullable,
# explicit NOT NULL still renders.
unlike($ddl, qr/"optional"\s+VARCHAR\(64\) NOT NULL/,
  'an explicit is_nullable => 1 column stays nullable');

like($ddl, qr/"required"\s+VARCHAR\(64\) NOT NULL/,
  'an explicit is_nullable => 0 column deploys as NOT NULL');

done_testing;
