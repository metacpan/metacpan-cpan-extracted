use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# --- Schema setup ---

{
  package TestDBIO::CLUpdate::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}

{
  package TestDBIO::CLUpdate::Schema::Result::Article;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('article');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    title   => { data_type => 'varchar', size => 200 },
    body    => { data_type => 'text', is_nullable => 1 },
    status  => { data_type => 'varchar', size => 20 },
    # excluded from changelog
    private_note => { data_type => 'text', changelog => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::CLUpdate::Schema->register_class(
  Article => 'TestDBIO::CLUpdate::Schema::Result::Article'
);

# --- Connect with fake storage ---

my $schema = TestDBIO::CLUpdate::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
$schema->_changelog_sources_registered(0);
$schema->_register_changelog_sources;

my $storage = $schema->storage;

# --- Helper: create a row "in storage" ---

sub make_in_storage {
  my ($id, $title, $body, $status, $private_note) = @_;
  my $article = $schema->resultset('Article')->new_result({
    id => $id,
    title => $title,
    body => $body,
    status => $status,
    private_note => $private_note,
  });
  $article->in_storage(1);
  $article->{_column_data_in_storage} = {
    id => $id,
    title => $title,
    body => $body,
    status => $status,
    private_note => $private_note // undef,
  };
  $article->{_dirty_columns} = {};
  return $article;
}

# --- Tests ---

subtest 'update single column records diff' => sub {
  $storage->reset_captured;

  my $article = make_in_storage(1, 'Original Title', 'Content here', 'draft', 'secret');

  $article->update({ title => 'Updated Title' });

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /article_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'changelog entry created for update');
};

subtest 'update excluded column alone does not create entry' => sub {
  $storage->reset_captured;

  my $article = make_in_storage(2, 'Title', 'Body', 'draft', 'old note');

  $article->update({ private_note => 'new secret note' });

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /article_changelog/i
  } $storage->captured_queries;

  is(scalar @cl_inserts, 0, 'no entry when only excluded column changes');
};

subtest 'update mix of tracked and excluded columns' => sub {
  $storage->reset_captured;

  my $article = make_in_storage(3, 'Old Title', 'Old body', 'draft', 'old');

  $article->update({
    title => 'New Title',
    private_note => 'new private',
  });

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /article_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'entry created when tracked column changes');
};

subtest 'update with no actual changes skips changelog' => sub {
  $storage->reset_captured;

  my $article = make_in_storage(4, 'Same', 'Same', 'same', 'same');

  $article->update({ title => 'Same' });  # same value

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /article_changelog/i
  } $storage->captured_queries;

  is(scalar @cl_inserts, 0, 'no entry when values are identical');
};

subtest 'update multiple columns records all diffs' => sub {
  $storage->reset_captured;

  my $article = make_in_storage(5, 'Title A', 'Body A', 'draft', 'secret');

  $article->update({
    title => 'Title B',
    body  => 'Body B',
    status => 'published',
  });

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /article_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'entry created for multi-column update');
};

subtest 'update sets changeset_id when inside txn_do' => sub {
  $storage->reset_captured;

  $schema->txn_do(sub {
    my $article = $schema->resultset('Article')->new_result({
      title => 'TX Article',
      body  => 'Content',
      status => 'draft',
    });
    $article->in_storage(1);
    $article->{_column_data_in_storage} = {
      id => 10, title => 'TX Article', body => 'Content', status => 'draft',
    };

    $article->update({ status => 'review' });

    my @cl_inserts = grep {
      $_->{op} eq 'insert' && $_->{sql} =~ /article_changelog/i
    } $storage->captured_queries;

    ok(scalar @cl_inserts, 'changelog entry inside txn_do');
  });

  my @cs_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /changelog_set/i
  } $storage->captured_queries;

  ok(scalar @cs_inserts, 'changeset created for txn_do with update');
};

subtest 'update with NULL in old value and new value' => sub {
  $storage->reset_captured;

  my $article = make_in_storage(6, 'Title', undef, 'draft', undef);

  $article->update({ body => 'Now we have content' });

  my @cl_inserts = grep {
    $_->{op} eq 'insert' && $_->{sql} =~ /article_changelog/i
  } $storage->captured_queries;

  ok(scalar @cl_inserts, 'entry created when NULL becomes defined');
};

done_testing;