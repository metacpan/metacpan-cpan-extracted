use strict;
use warnings;
use Test::More;

use DBIO::SQLite::Util qw(selectall_hashrefs);

# A PRAGMA that returns no rows -- foreign_key_list of a table without keys --
# or that the library does not know has no result columns. DBI before 1.635
# croaks in fetchall_arrayref({}) on such a statement ("invalid number of
# arguments" in bind_columns) where later DBI returns []. The introspection
# must read both the same: no columns means no rows, never an exception.

# (a) A statement handle that behaves like DBI 1.634 whatever DBI is installed.
{
  package Test::OldDBI::STH;
  sub new { bless {}, shift }
  sub execute { 1 }
  sub fetchall_arrayref {
    die "DBI bind_columns: invalid number of arguments: got handle + 0\n";
  }
  sub finish { 1 }
  sub FETCH {
    my ($self, $key) = @_;
    return $key eq 'NUM_OF_FIELDS' ? 0 : undef;
  }

  package Test::OldDBI::DBH;
  sub new { bless {}, shift }
  sub prepare { Test::OldDBI::STH->new }
}

my $fake = Test::OldDBI::DBH->new;
my $rows = eval { selectall_hashrefs($fake, 'PRAGMA foreign_key_list("t")') };
is($@, '', 'statement with NUM_OF_FIELDS 0 does not reach the croaking fetch');
is_deeply($rows, [], '... and reads as no rows');

# (b) The real thing.
require DBI;
my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
  { RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE TABLE plain (id INTEGER PRIMARY KEY, name TEXT)');

is_deeply(selectall_hashrefs($dbh, 'PRAGMA foreign_key_list("plain")'), [],
  'PRAGMA foreign_key_list of a table without keys: no rows');
is_deeply(selectall_hashrefs($dbh, 'PRAGMA dbio_no_such_pragma'), [],
  'a PRAGMA the library does not know: no rows');

my $cols = selectall_hashrefs($dbh, 'PRAGMA table_info("plain")');
is_deeply([ map { $_->{name} } @$cols ], [qw(id name)],
  'a statement with result columns still comes back as hashes');

done_testing;
