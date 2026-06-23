use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# --- Set up a minimal schema with ChangeLog ---

{
  package TestDBIO::CL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}

{
  package TestDBIO::CL::Schema::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
    secret => { data_type => 'varchar', size => 255, is_nullable => 1, changelog => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package TestDBIO::CL::Schema::Result::TwoKeyThing;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('two_key_thing');
  __PACKAGE__->add_columns(
    artist_id => { data_type => 'integer' },
    cd_id     => { data_type => 'integer' },
    notes     => { data_type => 'varchar', size => 255, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key(qw/ artist_id cd_id /);
}

TestDBIO::CL::Schema->register_class(
  Artist => 'TestDBIO::CL::Schema::Result::Artist'
);
TestDBIO::CL::Schema->register_class(
  TwoKeyThing => 'TestDBIO::CL::Schema::Result::TwoKeyThing'
);

# --- Connect with fake storage ---

my $schema = TestDBIO::CL::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));

# Re-register changelog sources since we replaced storage after connect
$schema->_changelog_sources_registered(0);
$schema->_register_changelog_sources;

my $storage = $schema->storage;

# Verify changelog sources are registered
ok($schema->source('ChangeLog_Set'), 'ChangeLog_Set source is registered');
ok($schema->source('Artist_ChangeLog'), 'Artist_ChangeLog source is registered');
ok($schema->source('TwoKeyThing_ChangeLog'), 'TwoKeyThing_ChangeLog source is registered');

# --- Test: insert creates a changelog entry ---
subtest 'insert creates changelog entry' => sub {
  $storage->reset_captured;

  my $artist = $schema->resultset('Artist')->new_result({
    name   => 'Miles Davis',
    secret => 'hidden',
  });
  $artist->insert;

  # Find the INSERT into artist_changelog
  my @queries = $storage->captured_queries;
  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /artist_changelog/i
  } @queries;

  ok(scalar @cl_inserts, 'changelog INSERT was generated for artist insert');

  # Verify the SQL mentions the right table
  if (@cl_inserts) {
    like($cl_inserts[0]{sql}, qr/artist_changelog/,
      'insert changelog targets artist_changelog table');
  }
};

# --- Test: update creates a changelog entry with diffs ---
subtest 'update creates changelog entry with diffs' => sub {
  $storage->reset_captured;

  # Create an artist that is "in storage"
  my $artist = $schema->resultset('Artist')->new_result({
    id   => 42,
    name => 'Miles Davis',
  });
  $artist->in_storage(1);
  # Simulate that these values are in storage
  $artist->{_column_data_in_storage} = { id => 42, name => 'Miles Davis' };
  $artist->{_dirty_columns} = {};

  # Now update
  $artist->update({ name => 'Miles Dewey Davis' });

  my @queries = $storage->captured_queries;
  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /artist_changelog/i
  } @queries;

  ok(scalar @cl_inserts, 'changelog INSERT was generated for artist update');
};

# --- Test: update with no dirty tracked columns skips changelog ---
subtest 'update with only excluded columns skips changelog' => sub {
  $storage->reset_captured;

  my $artist = $schema->resultset('Artist')->new_result({
    id     => 43,
    name   => 'Coltrane',
    secret => 'old_secret',
  });
  $artist->in_storage(1);
  $artist->{_column_data_in_storage} = { id => 43, name => 'Coltrane', secret => 'old_secret' };
  $artist->{_dirty_columns} = {};

  # Update only the excluded column
  $artist->update({ secret => 'new_secret' });

  my @queries = $storage->captured_queries;
  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /artist_changelog/i
  } @queries;

  is(scalar @cl_inserts, 0, 'no changelog entry for excluded-only column changes');
};

# --- Test: delete creates a changelog entry ---
subtest 'delete creates changelog entry' => sub {
  $storage->reset_captured;

  my $artist = $schema->resultset('Artist')->new_result({
    id   => 44,
    name => 'Thelonious Monk',
    secret => 'hidden',
  });
  $artist->in_storage(1);

  $artist->delete;

  my @queries = $storage->captured_queries;
  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /artist_changelog/i
  } @queries;

  ok(scalar @cl_inserts, 'changelog INSERT was generated for artist delete');
};

# --- Test: changelog column-info exclusion ---
subtest 'changelog column-info exclusion' => sub {
  my $artist_excluded = TestDBIO::CL::Schema::Result::Artist
    ->result_source_instance->columns_info;
  ok($artist_excluded->{secret}{_changelog_exclude}, 'secret is flagged for changelog exclusion');
  ok(!$artist_excluded->{name}{_changelog_exclude}, 'name is not excluded');

  my $tk_info = TestDBIO::CL::Schema::Result::TwoKeyThing
    ->result_source_instance->columns_info;
  ok(!grep({ $_->{_changelog_exclude} } values %$tk_info),
    'TwoKeyThing has no excluded columns');
};

# --- Test: log_event for custom events ---
subtest 'log_event creates custom changelog entry' => sub {
  $storage->reset_captured;

  my $artist = $schema->resultset('Artist')->new_result({
    id   => 45,
    name => 'Herbie Hancock',
  });
  $artist->in_storage(1);

  $artist->log_event('approved', { by => 'admin', reason => 'verified' });

  my @queries = $storage->captured_queries;
  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /artist_changelog/i
  } @queries;

  ok(scalar @cl_inserts, 'changelog INSERT was generated for custom event');
};

# --- Test: multi-column PK serialization ---
subtest 'multi-column PK serialization' => sub {
  $storage->reset_captured;

  my $thing = $schema->resultset('TwoKeyThing')->new_result({
    artist_id => 1,
    cd_id     => 2,
    notes     => 'test',
  });
  $thing->insert;

  my @queries = $storage->captured_queries;
  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /two_key_thing_changelog/i
  } @queries;

  ok(scalar @cl_inserts, 'changelog INSERT was generated for multi-PK insert');
};

# --- Test: txn_do creates changesets ---
subtest 'txn_do creates changeset' => sub {
  $storage->reset_captured;

  $schema->changelog_user('user_123');
  $schema->changelog_session('sess_456');

  $schema->txn_do(sub {
    my $artist = $schema->resultset('Artist')->new_result({
      name => 'Wayne Shorter',
    });
    $artist->insert;
  });

  my @queries = $storage->captured_queries;

  # There should be an INSERT into changelog_set
  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } @queries;

  ok(scalar @cs_inserts, 'changeset INSERT was generated inside txn_do');

  # And an INSERT into artist_changelog
  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /artist_changelog/i
  } @queries;

  ok(scalar @cl_inserts, 'changelog entry INSERT was generated inside txn_do');
};

# --- Test: nested txn_do reuses changeset ---
subtest 'nested txn_do reuses parent changeset' => sub {
  $storage->reset_captured;

  $schema->txn_do(sub {
    $schema->txn_do(sub {
      my $artist = $schema->resultset('Artist')->new_result({
        name => 'Ron Carter',
      });
      $artist->insert;
    });
  });

  my @queries = $storage->captured_queries;

  # Only ONE changeset should be created (not two)
  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } @queries;

  is(scalar @cs_inserts, 1, 'only one changeset created for nested txn_do');
};

# --- Test: changelog accessor returns ResultSet ---
subtest 'changelog accessor' => sub {
  my $artist = $schema->resultset('Artist')->new_result({
    id   => 50,
    name => 'Art Blakey',
  });
  $artist->in_storage(1);

  my $cl_rs = $artist->changelog;
  isa_ok($cl_rs, 'DBIO::ResultSet', 'changelog returns a ResultSet');
};

# --- Test: driver override hooks exist ---
subtest 'driver override hooks are defined' => sub {
  my $artist = $schema->resultset('Artist')->new_result({
    id => 99, name => 'Test',
  });

  can_ok($artist, 'changelog_column_definitions');
  can_ok($artist, 'changelog_serialize_changes');
  can_ok($artist, 'changelog_deserialize_changes');
  can_ok($artist, 'changelog_write_entry');
  can_ok($artist, 'changelog_notify');
};

# --- Test: serialize/deserialize roundtrip ---
subtest 'JSON serialize/deserialize roundtrip' => sub {
  my $artist = $schema->resultset('Artist')->new_result({
    id => 99, name => 'Test',
  });

  my $data = { name => ['old', 'new'], rank => [1, 2] };
  my $serialized = $artist->changelog_serialize_changes($data);
  ok(defined $serialized, 'serialize produces output');

  my $deserialized = $artist->changelog_deserialize_changes($serialized);
  is_deeply($deserialized, $data, 'deserialize round-trips correctly');
};

done_testing;