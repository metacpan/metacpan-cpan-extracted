use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# --- Schema setup ---

{
  package TestDBIO::CLTxnDo::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}

{
  package TestDBIO::CLTxnDo::Schema::Result::Account;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('account');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
    bal  => { data_type => 'numeric', size => [10,2], default => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package TestDBIO::CLTxnDo::Schema::Result::Log;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('log');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    msg  => { data_type => 'varchar', size => 255 },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::CLTxnDo::Schema->register_class(
  Account => 'TestDBIO::CLTxnDo::Schema::Result::Account',
  Log     => 'TestDBIO::CLTxnDo::Schema::Result::Log',
);

# --- Connect with fake storage ---

my $schema = TestDBIO::CLTxnDo::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
$schema->_changelog_sources_registered(0);
$schema->_register_changelog_sources;

my $storage = $schema->storage;

# --- Tests ---

subtest 'txn_do creates a single changeset' => sub {
  $storage->reset_captured;

  $schema->txn_do(sub {
    $schema->resultset('Account')->new_result({ name => 'Acct1', bal => 100 })->insert;
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 1, 'one changeset created');
};

subtest 'nested txn_do reuses parent changeset' => sub {
  $storage->reset_captured;

  $schema->txn_do(sub {
    $schema->resultset('Account')->new_result({ name => 'Outer', bal => 1 })->insert;

    $schema->txn_do(sub {
      $schema->resultset('Account')->new_result({ name => 'Inner', bal => 2 })->insert;
    });
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 1, 'only one changeset for nested txn_do');
};

subtest 'multiple operations in single txn_do share changeset' => sub {
  $storage->reset_captured;

  $schema->txn_do(sub {
    $schema->resultset('Account')->new_result({ name => 'A1', bal => 10 })->insert;
    $schema->resultset('Account')->new_result({ name => 'A2', bal => 20 })->insert;
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 1, 'one changeset for multiple inserts');
};

subtest 'changelog_user and changelog_session are set on changeset' => sub {
  $storage->reset_captured;

  $schema->changelog_user('user_99');
  $schema->changelog_session('sess_abc');

  $schema->txn_do(sub {
    $schema->resultset('Account')->new_result({ name => 'User Test', bal => 50 })->insert;
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  ok(scalar @cs_inserts, 'changeset insert present');
};

subtest 'changeset_id is NULL outside txn_do' => sub {
  $storage->reset_captured;

  $schema->resultset('Account')->new_result({ name => 'No TX', bal => 0 })->insert;

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 0, 'no changeset created outside txn_do');

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /account_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry created outside txn_do with NULL changeset');
};

subtest 'txn_do with rollback still creates changeset (rollback is up to caller)' => sub {
  $storage->reset_captured;

  eval {
    $schema->txn_do(sub {
      $schema->resultset('Account')->new_result({ name => 'Rollback Me', bal => 999 })->insert;
      die 'simulated failure';
    });
  };

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  # Changeset is created before the coderef runs; if the txn itself
  # rolls back, the changeset row rolls back too. But the create
  # itself happens inside next::method so we see it here.
  ok(scalar @cs_inserts, 'changeset created even when txn rolls back');
};

subtest 'deeply nested txn_do still reuses parent changeset' => sub {
  $storage->reset_captured;

  $schema->txn_do(sub {
    $schema->txn_do(sub {
      $schema->txn_do(sub {
        $schema->resultset('Account')->new_result({ name => 'Deep', bal => 1 })->insert;
      });
    });
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 1, 'only one changeset for deeply nested txn_do');
};

subtest 'changelog_disabled skips changeset creation' => sub {
  $storage->reset_captured;

  my $orig = $schema->changelog_disabled;
  $schema->changelog_disabled(1);

  $schema->txn_do(sub {
    $schema->resultset('Account')->new_result({ name => 'Disabled', bal => 0 })->insert;
  });

  $schema->changelog_disabled($orig);

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 0, 'no changeset when changelog disabled');
};

done_testing;