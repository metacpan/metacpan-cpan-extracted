use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# --- Schema setup ---

{
  package TestDBIO::CLInsert::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}

{
  package TestDBIO::CLInsert::Schema::Result::Item;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    name  => { data_type => 'varchar', size => 100 },
    desc  => { data_type => 'varchar', size => 255, is_nullable => 1 },
    cost  => { data_type => 'numeric', size => [10,2], is_nullable => 1 },
    # changelog => 0 — excluded from tracking
    internal_notes => { data_type => 'text', changelog => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::CLInsert::Schema->register_class(
  Item => 'TestDBIO::CLInsert::Schema::Result::Item'
);

# --- Connect with fake storage ---

my $schema = TestDBIO::CLInsert::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
$schema->_changelog_sources_registered(0);
$schema->_register_changelog_sources;

my $storage = $schema->storage;

# --- Tests ---

subtest 'insert records all tracked columns' => sub {
  $storage->reset_captured;

  my $item = $schema->resultset('Item')->new_result({
    name  => 'Widget',
    desc  => 'A test widget',
    cost  => 19.99,
    internal_notes => 'secret memo',
  });
  $item->insert;

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /item_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry was created for insert');

  # internal_notes should be excluded
  my $excl = $item->_changelog_excluded_columns;
  ok($excl->{internal_notes}, 'internal_notes is marked as excluded');
};

subtest 'insert with NULL tracked columns' => sub {
  $storage->reset_captured;

  my $item = $schema->resultset('Item')->new_result({
    name => 'Null Item',
    desc => undef,
    cost => undef,
  });
  $item->insert;

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /item_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry created even with NULL columns');
};

subtest 'insert without changelog component does not log' => sub {
  $storage->reset_captured;

  # A result class without ChangeLog loaded
  {
    package TestDBIO::CLInsert::Schema::Result::NoCLItem;
    use base 'DBIO::Core';
    __PACKAGE__->table('no_cl_item');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      data => { data_type => 'varchar', size => 100 },
    );
    __PACKAGE__->set_primary_key('id');
  }
  $schema->register_extra_source('NoCLItem',
    TestDBIO::CLInsert::Schema::Result::NoCLItem->result_source_instance);

  my $item = $schema->resultset('NoCLItem')->new_result({ data => 'test' });
  $item->insert;

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /no_cl_item_changelog/i
  } $storage->captured_queries;

  is(scalar @cl_inserts, 0, 'no changelog entry without ChangeLog component');
};

subtest 'insert with disabled changelog skips logging' => sub {
  $storage->reset_captured;

  my $item = $schema->resultset('Item')->new_result({
    name => 'Disabled Test',
  });

  # Temporarily disable changelog
  my $orig_disabled = $schema->changelog_disabled;
  $schema->changelog_disabled(1);
  $item->insert;
  $schema->changelog_disabled($orig_disabled);

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /item_changelog/i
  } $storage->captured_queries;

  is(scalar @cl_inserts, 0, 'no changelog entry when disabled');
};

subtest 'insert outside txn_do does not create changeset (user/session are for txn context)' => sub {
  $storage->reset_captured;

  $schema->changelog_user('admin_42');
  $schema->changelog_session('sess_abc');

  my $item = $schema->resultset('Item')->new_result({
    name => 'Logged Item',
  });
  $item->insert;

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 0, 'no changeset created outside txn_do');
};

done_testing;