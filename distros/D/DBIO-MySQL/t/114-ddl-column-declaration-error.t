use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# karr k96 point 2. _mysql_column_type delegates the portable base types to
# DBIO::Schema::Type::canonical_column. That function refuses a column whose
# declaration is broken (a size that is neither a scalar nor an arrayref). The
# refusal used to be swallowed by an eval, and the column fell into the legacy
# alias path: a timestamp with a broken size came out as the bare alias, as if
# it had been declared without a size at all. A broken declaration is the
# caller's error and has to arrive there, not be rendered as a different column.

for my $type (qw(timestamp char numeric)) {
  my $ok = eval {
    DBIO::MySQL::DDL::_mysql_column_type({ data_type => $type, size => {} });
    1;
  };
  ok !$ok, "$type with a hashref size is refused";
  like $@, qr/size for column .* must be a scalar or an arrayref, got a HASH reference/,
    "$type: the refusal is core's, naming the declaration";
}

# The same refusal reaches install_ddl, i.e. whoever deploys the schema.
{
  package K96::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package K96::Schema::Result::Ev;
  use DBIO;

  __PACKAGE__->table('ev');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    at => { data_type => 'timestamp', size => {} },
  );
  __PACKAGE__->set_primary_key('id');
}
K96::Schema->register_class(Ev => 'K96::Schema::Result::Ev');

my $ddl = eval { DBIO::MySQL::DDL->install_ddl('K96::Schema') };
like $@, qr/must be a scalar or an arrayref/, 'install_ddl does not render the column as a bare alias'
  or diag $ddl;

# What stays: well-formed declarations render as before.
is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'char', size => [10] }),
  'CHAR(10)', 'a well-formed size still renders');

done_testing;
