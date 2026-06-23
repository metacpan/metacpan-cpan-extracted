use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# --- Schema setup ---

{
  package TestDBIO::CLCustom::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}

{
  package TestDBIO::CLCustom::Schema::Result::Document;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('document');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    title    => { data_type => 'varchar', size => 200 },
    approved => { data_type => 'varchar', size => 20, default => 'pending' },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::CLCustom::Schema->register_class(
  Document => 'TestDBIO::CLCustom::Schema::Result::Document'
);

# --- Connect with fake storage ---

my $schema = TestDBIO::CLCustom::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
$schema->_changelog_sources_registered(0);
$schema->_register_changelog_sources;

my $storage = $schema->storage;

# --- Tests ---

subtest 'log_event creates entry with custom event name' => sub {
  $storage->reset_captured;

  my $doc = $schema->resultset('Document')->new_result({
    id    => 1,
    title => 'Test Doc',
  });
  $doc->in_storage(1);

  $doc->log_event('approved', { by => 'admin_1', reason => 'looks good' });

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /document_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry created for custom event');
};

subtest 'log_event with no details uses empty hashref' => sub {
  $storage->reset_captured;

  my $doc = $schema->resultset('Document')->new_result({
    id    => 2,
    title => 'No Details',
  });
  $doc->in_storage(1);

  $doc->log_event('viewed');

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /document_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'entry created even with no details');
};

subtest 'log_event inside txn_do has changeset_id' => sub {
  $storage->reset_captured;

  my $doc = $schema->resultset('Document')->new_result({
    id    => 3,
    title => 'TX Event',
  });
  $doc->in_storage(1);

  $schema->txn_do(sub {
    $doc->log_event('processed', { processor => 'batch_job' });
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  ok(scalar @cs_inserts, 'changeset created for txn_do with log_event');

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /document_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry inside txn_do');
};

subtest 'log_event outside txn_do has NULL changeset_id' => sub {
  $storage->reset_captured;

  my $doc = $schema->resultset('Document')->new_result({
    id    => 4,
    title => 'No TX Event',
  });
  $doc->in_storage(1);

  $doc->log_event('manual_review');

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  is(scalar @cs_inserts, 0, 'no changeset outside txn_do');
};

subtest 'log_event with deeply nested details' => sub {
  $storage->reset_captured;

  my $doc = $schema->resultset('Document')->new_result({
    id    => 5,
    title => 'Nested Details',
  });
  $doc->in_storage(1);

  $doc->log_event('state_change', {
    from => { status => 'draft', assignee => undef },
    to   => { status => 'review', assignee => 'user_42' },
    via  => 'workflow_engine',
  });

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /document_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'entry created with complex nested details');
};

subtest 'log_event triggers changelog_notify callback' => sub {
  my $doc = $schema->resultset('Document')->new_result({
    id    => 6,
    title => 'Notify Test',
  });
  $doc->in_storage(1);

  my $notified_event;
  my $notified_entry;

  # Override changelog_notify via package-level method override
  no strict 'refs';
  my $orig = \&{'TestDBIO::CLCustom::Schema::Result::Document::changelog_notify'};
  *{'TestDBIO::CLCustom::Schema::Result::Document::changelog_notify'} = sub {
    my ($self, $event, $entry) = @_;
    $notified_event = $event;
    $notified_entry = $entry;
  };

  $doc->log_event('test_notify', { key => 'value' });

  is($notified_event, 'test_notify', 'notify called with event name');
  ok($notified_entry, 'notify called with entry hashref');

  # Restore original
  *{'TestDBIO::CLCustom::Schema::Result::Document::changelog_notify'} = $orig;
  use strict;
};

subtest 'log_event with disabled changelog skips logging' => sub {
  $storage->reset_captured;

  my $doc = $schema->resultset('Document')->new_result({
    id    => 7,
    title => 'Disabled Event',
  });
  $doc->in_storage(1);

  my $orig = $schema->changelog_disabled;
  $schema->changelog_disabled(1);
  $doc->log_event('should_not_log');
  $schema->changelog_disabled($orig);

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /document_changelog/i
  } $storage->captured_queries;

  is(scalar @cl_inserts, 0, 'no entry when changelog disabled');
};

done_testing;