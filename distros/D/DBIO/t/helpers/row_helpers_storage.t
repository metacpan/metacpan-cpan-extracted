use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test::Storage;

# --- StorageValues test schema ---------------------------------------

{
  package TestSV::Schema;
  use base 'DBIO::Schema';
}

{
  package TestSV::Schema::Result::Post;
  use base 'DBIO::Core';

  __PACKAGE__->table('post');
  __PACKAGE__->add_columns(
    id => {
      data_type         => 'integer',
      is_auto_increment => 1,
    },
    title => {
      data_type          => 'varchar',
      size               => 100,
      keep_storage_value => 1,
    },
    body => {
      data_type => 'text',
      is_nullable => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');
}

TestSV::Schema->register_class(Post => 'TestSV::Schema::Result::Post');

# --- OnColumnChange test schema --------------------------------------

{
  package TestOCC::Changes;
  our @LOG;
  sub reset { @LOG = () }
  sub all   { @LOG }
}

{
  package TestOCC::Schema;
  use base 'DBIO::Schema';
}

{
  package TestOCC::Schema::Result::Account;
  use base 'DBIO::Core';

  __PACKAGE__->table('account');
  __PACKAGE__->add_columns(
    id => {
      data_type         => 'integer',
      is_auto_increment => 1,
    },
    amount => {
      data_type          => 'integer',
      keep_storage_value => 1,
    },
    owner => {
      data_type   => 'varchar',
      size        => 100,
      is_nullable => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->before_column_change(
    amount => { method => 'record_before' },
  );
  __PACKAGE__->after_column_change(
    amount => { method => 'record_after' },
  );

  sub record_before {
    my ($self, $old, $new) = @_;
    push @TestOCC::Changes::LOG,
      { phase => 'before', column => 'amount', old => $old, new => $new };
  }

  sub record_after {
    my ($self, $old, $new) = @_;
    push @TestOCC::Changes::LOG,
      { phase => 'after', column => 'amount', old => $old, new => $new };
  }
}

TestOCC::Schema->register_class(
  Account => 'TestOCC::Schema::Result::Account'
);

# --- ProxyResultSetMethod test schema --------------------------------

{
  package TestPRM::Schema;
  use base 'DBIO::Schema';
}

{
  package TestPRM::Schema::ResultSet::Widget;
  use base 'DBIO::ResultSet';

  sub with_score {
    my $self = shift;
    return $self->search(undef, { '+columns' => { score => \'42' } });
  }
}

{
  package TestPRM::Schema::Result::Widget;
  use base 'DBIO::Core';

  __PACKAGE__->table('widget');
  __PACKAGE__->resultset_class('TestPRM::Schema::ResultSet::Widget');
  __PACKAGE__->add_columns(
    id => {
      data_type         => 'integer',
      is_auto_increment => 1,
    },
    name => {
      data_type => 'varchar',
      size      => 100,
    },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->proxy_resultset_method('score');
}

TestPRM::Schema->register_class(Widget => 'TestPRM::Schema::Result::Widget');

# --- Connect all three schemas to fake storage -----------------------

sub connect_fake {
  my $schema_class = shift;
  my $schema = $schema_class->connect(sub { });
  $schema->storage(DBIO::Test::Storage->new($schema));
  return $schema;
}

subtest 'StorageValues: snapshot + get_storage_value + refresh' => sub {
  my $schema = connect_fake('TestSV::Schema');
  my $rs     = $schema->resultset('Post');

  my $post = $rs->new_result({ title => 'First draft', body => 'hello' });

  is_deeply(
    $post->storage_value_columns,
    ['title'],
    'only keep_storage_value columns are snapshotted'
  );

  ok(defined $post->_storage_values, '_storage_values is initialised in new');

  $post->insert;

  is($post->get_storage_value('title'), 'First draft',
    'after insert, storage_value matches the inserted value');

  $post->title('Second draft');
  is($post->get_storage_value('title'), 'First draft',
    'dirty change does not update storage_value');

  $post->update;
  is($post->get_storage_value('title'), 'Second draft',
    'after update, storage_value is refreshed');

  # inflate_result path
  my $rsrc = $schema->source('Post');
  my $inflated = TestSV::Schema::Result::Post->inflate_result(
    $rsrc, { id => 7, title => 'Via inflate_result', body => 'x' }
  );
  is($inflated->get_storage_value('title'), 'Via inflate_result',
    'inflate_result captures storage value');
};

subtest 'OnColumnChange: before/after fire with correct args' => sub {
  my $schema = connect_fake('TestOCC::Schema');
  my $rs     = $schema->resultset('Account');

  # Create and insert an account
  TestOCC::Changes::reset();
  my $acc = $rs->new_result({ amount => 100, owner => 'alice' });
  $acc->insert;

  # No callbacks should fire on insert
  is(scalar TestOCC::Changes::all(), 0,
    'callbacks do not fire on insert');

  # Dirty the tracked column and update
  $acc->amount(250);
  $acc->update;

  my @log = TestOCC::Changes::all();
  is(scalar @log, 2, 'before + after callbacks fired');

  is($log[0]{phase}, 'before', 'before fires first');
  is($log[0]{old},   100,       'before sees old storage value');
  is($log[0]{new},   250,       'before sees new value');

  is($log[1]{phase}, 'after',   'after fires last');
  # After callbacks get ($old, $new) where $old has been stored —
  # the post-update storage value matches the new value.
  is($log[1]{old},   250,       'after sees updated storage value');
  is($log[1]{new},   250,       'after sees new value');

  # Updating a non-registered column is a no-op for callbacks
  TestOCC::Changes::reset();
  $acc->owner('bob');
  $acc->update;
  is(scalar TestOCC::Changes::all(), 0,
    'non-registered column change does not trigger callbacks');

  # Confirm zero-cost for a class with no callbacks (the SV schema).
  my $post_schema = connect_fake('TestSV::Schema');
  my $post_rs     = $post_schema->resultset('Post');
  my $post = $post_rs->new_result({ title => 'x', body => 'y' });
  $post->insert;
  $post->title('z');
  lives_ok { $post->update } 'update on a class with no callbacks works';
};

subtest 'ProxyResultSetMethod: installs accessor, registers slot' => sub {
  my $schema = connect_fake('TestPRM::Schema');

  # Class method is installed as an accessor sub on the Result class
  can_ok(
    'TestPRM::Schema::Result::Widget',
    'score',
  );

  is_deeply(
    TestPRM::Schema::Result::Widget->_proxy_slots,
    ['score'],
    '_proxy_slots records the registered slot'
  );

  # Accessor hands back cached value if the slot is loaded
  my $rsrc = $schema->source('Widget');
  my $w = TestPRM::Schema::Result::Widget->inflate_result(
    $rsrc, { id => 1, name => 'cached', score => 99 }
  );
  is($w->score, 99, 'proxy accessor returns loaded value directly');

  # update() must not carry the proxy slot into the generated SQL.
  # Mark a real column dirty so an UPDATE actually fires, plus the
  # proxy slot to verify it gets stripped.
  $schema->storage->reset_captured;
  $w->{_dirty_columns}{score} = 1;
  $w->name('renamed');
  lives_ok {
    $w->update;
  } 'update with dirty proxy slot does not attempt to write it';

  my @queries = $schema->storage->captured_queries;
  my ($update) = grep { $_->{op} eq 'update' } @queries;
  ok($update, 'an UPDATE was issued');
  unlike($update->{sql}, qr/\bscore\b/,
    'UPDATE SQL does not include the proxy slot');
  like($update->{sql}, qr/\bname\b/,
    'UPDATE SQL includes the real dirty column');

  # copy() path: also must not carry the slot through.
  $w->{_column_data}{score} = 77;
  my $copy;
  lives_ok {
    $copy = $w->copy({ name => 'copied' });
  } 'copy with a proxy slot value does not die';
};

# --- DateTime snapshot immutability test -----------------------------

subtest 'StorageValues: DateTime clone prevents snapshot corruption' => sub {
  eval 'require DateTime; 1' or skip('DateTime not installed', 3);

  {
    package TestDT::Schema;
    use base 'DBIO::Schema';
  }

  {
    package TestDT::Schema::Result::Event;
    use base 'DBIO::Core';

    __PACKAGE__->table('event');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'varchar', size => 100 },
      occurred_at => {
        data_type          => 'timestamp with time zone',
        keep_storage_value => 1,
      },
    );
    __PACKAGE__->set_primary_key('id');
  }

  TestDT::Schema->register_class(Event => 'TestDT::Schema::Result::Event');

  my $schema = TestDT::Schema->connect(sub { });
  $schema->storage(DBIO::Test::Storage->new($schema));
  my $rs = $schema->resultset('Event');

  my $dt_original = DateTime->new(year => 2024, month => 1, day => 15,
                                   hour => 10, minute => 30, second => 0,
                                   time_zone => 'UTC');

  my $event = $rs->new_result({ name => 'launch', occurred_at => $dt_original });
  $event->insert;

  # Snapshot holds a clone — mutation of the original does not corrupt snapshot
  $dt_original->add(days => 99);

  my $snap = $event->get_storage_value('occurred_at');
  isnt($snap, $dt_original, 'snapshot is not the same object reference');
  is($snap->ymd, '2024-01-15', 'snapshot is unaffected by later mutation');

  # Mutation via the stored snapshot does not affect the row
  my $snap2 = $event->get_storage_value('occurred_at');
  $snap2->add(months => 6);

  my $snap3 = $event->get_storage_value('occurred_at');
  is($snap3->ymd, '2024-01-15', 'snapshot mutation does not propagate');
};

done_testing;
