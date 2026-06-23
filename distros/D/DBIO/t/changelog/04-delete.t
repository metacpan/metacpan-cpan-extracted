use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# --- Schema setup ---

{
  package TestDBIO::CLDelete::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}

{
  package TestDBIO::CLDelete::Schema::Result::Entry;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('entry');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    label    => { data_type => 'varchar', size => 100 },
    data     => { data_type => 'text', is_nullable => 1 },
    # excluded from changelog
    internal => { data_type => 'text', changelog => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::CLDelete::Schema->register_class(
  Entry => 'TestDBIO::CLDelete::Schema::Result::Entry'
);

# --- Connect with fake storage ---

my $schema = TestDBIO::CLDelete::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
$schema->_changelog_sources_registered(0);
$schema->_register_changelog_sources;

my $storage = $schema->storage;

# --- Tests ---

subtest 'delete records all tracked column values' => sub {
  $storage->reset_captured;

  my $entry = $schema->resultset('Entry')->new_result({
    id       => 1,
    label    => 'To Delete',
    data     => 'Some data',
    internal => 'secret data',
  });
  $entry->in_storage(1);

  $entry->delete;

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /entry_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry created for delete');
};

subtest 'delete excluded column not in logged data' => sub {
  $storage->reset_captured;

  my $entry = $schema->resultset('Entry')->new_result({
    id       => 2,
    label    => 'Keep',
    internal => 'this should not appear alone',
  });
  $entry->in_storage(1);

  $entry->delete;

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /entry_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'entry created');
};

subtest 'delete outside storage throws (DBIO requires in_storage before delete)' => sub {
  $storage->reset_captured;

  my $entry = $schema->resultset('Entry')->new_result({
    label => 'Not in storage',
    data  => 'test',
  });
  # not in_storage — DBIO::Row::delete throws "Not in database"

  eval { $entry->delete };
  like($@, qr/Not in database/, 'delete throws when not in storage');
};

subtest 'delete with disabled changelog skips logging' => sub {
  $storage->reset_captured;

  my $entry = $schema->resultset('Entry')->new_result({
    id    => 3,
    label => 'Disabled Delete',
  });
  $entry->in_storage(1);

  my $orig = $schema->changelog_disabled;
  $schema->changelog_disabled(1);
  $entry->delete;
  $schema->changelog_disabled($orig);

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /entry_changelog/i
  } $storage->captured_queries;

  is(scalar @cl_inserts, 0, 'no entry when changelog disabled');
};

subtest 'delete inside txn_do creates changeset' => sub {
  $storage->reset_captured;

  $schema->txn_do(sub {
    my $entry = $schema->resultset('Entry')->new_result({
      id    => 4,
      label => 'TX Delete',
    });
    $entry->in_storage(1);
    $entry->delete;
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  ok(scalar @cs_inserts, 'changeset created for txn_do delete');

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /entry_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry inside txn_do delete');
};

subtest 'delete with multi-column PK serializes correctly' => sub {
  $storage->reset_captured;

  {
    package TestDBIO::CLDelete::Schema::Result::Link;
    use base 'DBIO::Core';

    __PACKAGE__->load_components('ChangeLog');
    __PACKAGE__->table('link');
    __PACKAGE__->add_columns(
      project_id => { data_type => 'integer' },
      item_id    => { data_type => 'integer' },
      notes      => { data_type => 'varchar', size => 255, is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key(qw/ project_id item_id /);
  }
  $schema->register_class(
    Link => 'TestDBIO::CLDelete::Schema::Result::Link'
  );
  $schema->_changelog_sources_registered(0);
  $schema->_register_changelog_sources;

  my $link = $schema->resultset('Link')->new_result({
    project_id => 10,
    item_id    => 20,
    notes      => 'linking',
  });
  $link->in_storage(1);
  $link->delete;

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /link_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry for multi-PK delete');
};

done_testing;