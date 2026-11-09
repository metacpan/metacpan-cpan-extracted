use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Oracle::Deploy;

# LIVE (karr k51). The canonical index declarations (Cake idx, indices; ADR
# 0061 in core) reach the server: install creates them, a function-based
# index is what the data dictionary says it is.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;

{
  package T::K51::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
}
{
  package T::K51::Schema::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k51_live_doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    title => { data_type => 'varchar', size => 100 },
    state => { data_type => 'varchar', size => 20 },
    code  => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->set_primary_key('id');
  my $src = __PACKAGE__->result_source_instance;
  $src->add_index_declaration({ name => 'k51_doc_state', columns => ['state'] });
  $src->add_index_declaration({
    name => 'k51_doc_title_uq', columns => ['title'], unique => 1,
  });
  $src->add_index_declaration({
    name => 'k51_doc_lower', columns => ['title'],
    driver => { oracle => { expression => 'LOWER("title")' } },
  });
}
T::K51::Schema->register_class(Doc => 'T::K51::Schema::Result::Doc');

my $dbh = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});

sub wipe {
  $dbh->do('DROP TABLE "k51_live_doc" CASCADE CONSTRAINTS PURGE')
    for grep { 1 } @{ $dbh->selectcol_arrayref(
      q{SELECT table_name FROM user_tables WHERE table_name = 'k51_live_doc'}
    ) };
}

wipe();
my $deploy = DBIO::Oracle::Deploy->new(
  schema => T::K51::Schema->connect($dsn, $user, $pass),
);
eval { $deploy->install; 1 } or fail("install: $@");

my %idx = map { $_->[0] => $_ } @{ $dbh->selectall_arrayref(q{
  SELECT index_name, uniqueness, index_type FROM user_indexes
  WHERE table_name = 'k51_live_doc'
}) };

ok $idx{k51_doc_state}, 'plain declared index exists';
is $idx{k51_doc_title_uq}[1], 'UNIQUE', 'unique declared index is unique';
ok $idx{k51_doc_lower}, 'expression index exists';
like $idx{k51_doc_lower}[2], qr/FUNCTION-BASED/, 'it is function-based';

wipe();
done_testing;
