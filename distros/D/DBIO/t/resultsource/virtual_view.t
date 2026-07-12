use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# Backs the DBIO::ResultSource::View SYNOPSIS at runtime: a *virtual* view
# (is_virtual(1) + a view_definition) has no table in the database, so every
# query against it must inline the view_definition as a FROM subquery rather
# than referencing a table name.
#
# Existing coverage only constructs such classes (t/generate/*, base-introspect);
# nothing asserted the emitted runtime SQL. This does -- mock-only, via as_query
# so no database is touched.

{
  package TestDBIO::View::Schema;
  use base 'DBIO::Schema';
}
{
  package TestDBIO::View::Schema::Result::Year2000CDs;
  use base 'DBIO::Core';

  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('year2000cds');
  __PACKAGE__->result_source_instance->is_virtual(1);
  __PACKAGE__->result_source_instance->view_definition(
    "SELECT cdid, artist, title FROM cd WHERE year ='2000'"
  );
  __PACKAGE__->add_columns(
    cdid   => { data_type => 'integer', is_auto_increment => 1 },
    artist => { data_type => 'integer' },
    title  => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('cdid');
}

TestDBIO::View::Schema->register_class(
  Year2000CDs => 'TestDBIO::View::Schema::Result::Year2000CDs'
);

my $schema = TestDBIO::View::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));

my $source = $schema->source('Year2000CDs');
ok $source->is_virtual, 'the source reports itself virtual';

subtest 'a plain search inlines the view_definition as a FROM subquery' => sub {
  my $rs  = $schema->resultset('Year2000CDs');
  my $sql = ${ $rs->as_query }->[0];

  like $sql,
    qr/FROM \(SELECT cdid, artist, title FROM cd WHERE year ='2000'\)/,
    'the FROM clause wraps the view_definition as a subquery, not a table name';
  unlike $sql, qr/FROM\s+"?year2000cds"?\b/i,
    'the virtual view name never appears as a real table';
};

subtest 'a filtered search wraps the subquery and adds the outer WHERE' => sub {
  my $rs  = $schema->resultset('Year2000CDs')->search({ artist => 1 });
  my $sql = ${ $rs->as_query }->[0];

  like $sql,
    qr/FROM \(SELECT cdid, artist, title FROM cd WHERE year ='2000'\)/,
    'the subquery wrap still applies under a search condition';
  like $sql, qr/WHERE\b.*"artist"\s*=\s*\?/is,
    'the caller condition is applied in the outer query';
};

done_testing;
