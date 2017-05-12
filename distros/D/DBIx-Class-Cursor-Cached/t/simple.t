BEGIN {
  package SchemaClass::CD;

  use base qw(DBIx::Class::Core);

  __PACKAGE__->table('cd');
  __PACKAGE__->add_columns(
    'id' => {
      data_type => 'integer',
      is_auto_increment => 1,
    },
    'title' => {
      data_type => 'varchar',
      size      => 100,
    },
  );
  __PACKAGE__->set_primary_key('id');

  package SchemaClass;

  use base qw(DBIx::Class::Schema);

  __PACKAGE__->register_class(CD => 'SchemaClass::CD');

  sub deploy {
    my $self = shift;
    $self->storage->dbh->do(q{
      CREATE TABLE cd (
        id INTEGER PRIMARY KEY NOT NULL,
        title varchar(100) NOT NULL
      );
    });
  }

  sub init {
    my $self = shift;
    $self->deploy;
    $self->resultset('CD')->populate([
      map { { title => $_ } } 'CD one', 'CD two'
    ]);
  }

}

use Cache::FileCache;
use DBIx::Class::Cursor::Cached;
use Test::More 'no_plan';

mkdir('t/var');
unlink('t/var/test.db');

my ($dsn, $user, $pass) = ('dbi:SQLite:t/var/test.db');

SchemaClass->connect($dsn,$user,$pass)->init;

my $expect_data = [ [ 1, 'CD one' ], [ 2, 'CD two' ] ];

{ ## start test block

  my $schema = SchemaClass->connect(
    $dsn, $user, $pass, { cursor_class => 'DBIx::Class::Cursor::Cached' }
  );

  $schema->default_resultset_attributes({
    cache_object => Cache::FileCache->new({ namespace => 'SchemaClass' }),
  });

my $cache = $schema->default_resultset_attributes->{cache_object};

  my $rs = $schema->resultset('CD')->search(undef, { cache_for => 300 });

  my @cds = $rs->all; # fills cache

is_deeply([ map { [ $_->id, $_->title ] } @cds ], $expect_data,
  'correct data in objects');
is_deeply($cache->get($rs->cursor->cache_key), $expect_data,
  'correct data in cache');

  $rs = $schema->resultset('CD')->search(undef, { cache_for => 300 });
    # refresh resultset

$schema->storage->disconnect;

  @cds = $rs->all; # uses cache, no SQL run

ok(!$schema->storage->connected, 'no reconnect made since no SQL required');
is_deeply([ map { [ $_->id, $_->title ] } @cds ], $expect_data,
  'correct data in objects');
is_deeply($cache->get($rs->cursor->cache_key), $expect_data,
  'correct data in cache');

  $rs->cursor->clear_cache; # deletes data from cache

ok(!defined($cache->get($rs->cursor->cache_key)), 'cache cleared');

  @cds = (); while (my $rec = $rs->next) { push(@cds, $rec); }

is_deeply([ map { [ $_->id, $_->title ] } @cds ], $expect_data,
  'correct data in objects');
is_deeply($cache->get($rs->cursor->cache_key), $expect_data,
  'correct data in cache');

}

{
  my $schema = SchemaClass->connect(
    sub {
      DBI->connect('dbi:SQLite:t/var/test.db', '', '', { RaiseError => 1 }) },
        { cursor_class => 'DBIx::Class::Cursor::Cached' }
  );

  $schema->default_resultset_attributes({
    cache_object => Cache::FileCache->new({ namespace => 'SchemaClass' }),
  });

my $cache = $schema->default_resultset_attributes->{cache_object};

  my $rs = $schema->resultset('CD')->search(undef, { cache_for => 300 });

  my @cds = $rs->all; # fills cache

is_deeply([ map { [ $_->id, $_->title ] } @cds ], $expect_data,
  'correct data in objects');
is_deeply($cache->get($rs->cursor->cache_key), $expect_data,
  'correct data in cache');

  $rs = $schema->resultset('CD')->search(undef, { cache_for => 300 });
    # refresh resultset

$schema->storage->disconnect;

  @cds = $rs->all; # uses cache, no SQL run

ok(!$schema->storage->connected, 'no reconnect made since no SQL required');
is_deeply([ map { [ $_->id, $_->title ] } @cds ], $expect_data,
  'correct data in objects');
is_deeply($cache->get($rs->cursor->cache_key), $expect_data,
  'correct data in cache');

  $rs->cursor->clear_cache; # deletes data from cache

ok(!defined($cache->get($rs->cursor->cache_key)), 'cache cleared');

  @cds = (); while (my $rec = $rs->next) { push(@cds, $rec); }

is_deeply([ map { [ $_->id, $_->title ] } @cds ], $expect_data,
  'correct data in objects');
is_deeply($cache->get($rs->cursor->cache_key), $expect_data,
  'correct data in cache');
}


