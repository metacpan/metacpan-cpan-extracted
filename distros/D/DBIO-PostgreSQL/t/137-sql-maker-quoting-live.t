use strict;
use warnings;
use Test::More;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# The future_io half needs the transport and a Future::IO loop; the sync half
# runs without them.
my $have_future_io = eval {
  require IO::Async::Loop;
  require Future::IO::Impl::IOAsync;
  Future::IO::Impl::IOAsync->import;
  require DBIO::PostgreSQL::Storage::Async;
  1;
};

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test, karr k121 point U5: quoting a connection turned off is off on the
# server too, and the default quotes.
#
# CLAIM, over two tables that differ only in the case of their column:
#   dbio_k121_fold    has the column  mixedcol    (what an unquoted
#                                                  MixedCol is folded to)
#   dbio_k121_quoted  has the column "MixedCol"   (only a quoted name finds it)
# A result class names its column MixedCol.
#   - with quote_names => 0 (alone), and with quote_char => '' (alone) the
#     statement carries MixedCol bare: it works against the folded column and
#     the server does not find "MixedCol" in the other table;
#   - by default the statement carries "MixedCol": it works against the quoted
#     column and the server does not find it in the folded table.
# The offline half, t/137-sql-maker-quoting.t, pins the text.
#
# The same cases over the future_io transport of the same connection (karr
# k121, maintainer's decision 2026-10-16): its INSERT and SELECT find the
# column the sync path finds and miss the one it misses. Before, the
# transport quoted whatever the connection said.

{
  package DBIO::Test::K121Quote::Result::Fold;
  $INC{'DBIO/Test/K121Quote/Result/Fold.pm'} = 1;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_k121_fold');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    MixedCol => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Test::K121Quote::Result::Quoted;
  $INC{'DBIO/Test/K121Quote/Result/Quoted.pm'} = 1;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_k121_quoted');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    MixedCol => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Test::K121Quote;
  $INC{'DBIO/Test/K121Quote.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Fold   => 'DBIO::Test::K121Quote::Result::Fold');
  __PACKAGE__->register_class(Quoted => 'DBIO::Test::K121Quote::Result::Quoted');
}

my $dbh = LiveServer->control_dbh;
$dbh->do('DROP TABLE IF EXISTS dbio_k121_fold');
$dbh->do('DROP TABLE IF EXISTS dbio_k121_quoted');
$dbh->do('CREATE TABLE dbio_k121_fold (id integer PRIMARY KEY, MixedCol text)');
$dbh->do('CREATE TABLE dbio_k121_quoted (id integer PRIMARY KEY, "MixedCol" text)');

END {
  if ($dbh) {
    local $@;
    eval {
      $dbh->do('DROP TABLE IF EXISTS dbio_k121_fold');
      $dbh->do('DROP TABLE IF EXISTS dbio_k121_quoted');
    };
  }
}

# true when the statement ran, the exception otherwise
sub works {
  my ($schema, $source) = @_;
  my $rs = $schema->resultset($source);
  my $ok = eval {
    $rs->delete({ all => 1 });
    $rs->create({ id => 1, MixedCol => 'v' });
    my @v = map { $_->get_column('MixedCol') } $rs->search({ MixedCol => 'v' })->all;
    is_deeply \@v, ['v'], "$source: the row is read back" or die "wrong rows\n";
    1;
  };
  return $ok ? 1 : (0, "$@");
}

# the same over the future_io transport: the insert and the select are
# written by its maker
sub works_async {
  my ($schema, $source) = @_;
  my $rs = $schema->resultset($source);
  my $ok = eval {
    $rs->delete({ all => 1 });
    $rs->create_async({ id => 1, MixedCol => 'v' })->get;
    my @v = map { $_->get_column('MixedCol') }
      $rs->search({ MixedCol => 'v' })->all_async->get;
    is_deeply \@v, ['v'], "$source: the row is read back over future_io"
      or die "wrong rows\n";
    1;
  };
  return $ok ? 1 : (0, "$@");
}

my @cases = (
  # name, connect attributes, source that works, source the server refuses
  [ 'default (nothing said)',  {},                  'Quoted', 'Fold'   ],
  [ 'quote_names => 0 alone',  { quote_names => 0 }, 'Fold',   'Quoted' ],
  [ q{quote_char => '' alone}, { quote_char => '' }, 'Fold',   'Quoted' ],
);

for my $case (@cases) {
  my ($name, $attrs, $good, $bad) = @$case;
  my $schema = DBIO::Test::K121Quote->connect($dsn, $user, $pass, { %$attrs });

  my ($ok) = works($schema, $good);
  ok $ok, "$name: $good (column written to match) works";

  my ($bad_ok, $why) = works($schema, $bad);
  ok !$bad_ok, "$name: $bad (column written the other way) is refused";
  like $why, qr/column .*(?:mixedcol|MixedCol).* does not exist/i,
    "$name: ... because the server does not find the column";

  $schema->storage->disconnect;

  SKIP: {
    skip 'future_io: DBIO::Async or Future::IO::Impl::IOAsync not installed', 3
      unless $have_future_io;

    my $async = DBIO::Test::K121Quote->connect(
      $dsn, $user, $pass, { %$attrs, async => 'future_io' },
    );

    my ($aok) = works_async($async, $good);
    ok $aok, "$name, future_io: $good (column written to match) works";

    my ($abad_ok, $awhy) = works_async($async, $bad);
    ok !$abad_ok, "$name, future_io: $bad (column written the other way) is refused";
    like $awhy, qr/column .*(?:mixedcol|MixedCol).* does not exist/i,
      "$name, future_io: ... because the server does not find the column";

    $async->storage->disconnect;
  }
}

done_testing;
