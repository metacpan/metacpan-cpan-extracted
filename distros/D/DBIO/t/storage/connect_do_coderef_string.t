use strict;
use warnings;
use Test::More;
use Test::Exception;

# OFFLINE (karr k290 c). A code reference inside on_connect_do /
# on_disconnect_do, or handed to do_sql, is called with the storage and
# answers the statements to run. What it may answer:
#   - an array reference: each element a scalar or [ $sql, \%attrs, @bind ]
#   - a plain string: one SQL statement, the same as [ $string ]
#   - nothing (undef, empty list, empty string): nothing is run
# Anything else (a hash reference, an object) is refused in plain words that
# name on_connect_do / do_sql -- not as the raw strict-refs error.
#
# The claim is that the string form is one statement on EVERY path a
# statement takes: the sync connect, the disconnect, and the replay on an
# async pool connection (_pool_connect_runner). The substitution is a storage
# whose dbh_do hands the statement to a recording handle.

use DBIO::Test;
use DBIO::Storage::DBI;

my @LOG;

{
  package T::K290::Dbh;
  sub new { bless {}, shift }
  sub do  { shift; push @LOG, [ @_ ]; 1 }
}

{
  package T::K290::Storage;
  use base 'DBIO::Storage::DBI';

  sub dbh_do {
    my ($self, $code, @args) = @_;
    $self->$code(T::K290::Dbh->new, @args);
  }
}

my $schema  = DBIO::Test->init_schema;   # storages weaken their schema ref
my $storage = T::K290::Storage->new($schema);

# --- _do_query / do_sql --------------------------------------------------

@LOG = ();
$storage->_do_query(sub { 'select 1' });
is_deeply \@LOG, [ [ 'select 1', undef ] ],
  'a code reference answering a string runs it as one statement';

@LOG = ();
$storage->_do_query(sub { [ 'select 2', [ 'select 3', { a => 1 }, 'b' ] ] });
is_deeply \@LOG, [ [ 'select 2', undef ], [ 'select 3', { a => 1 }, 'b' ] ],
  'an array reference answer is unchanged: elements run in order';

@LOG = ();
$storage->_do_query(sub { return });
$storage->_do_query(sub { undef });
$storage->_do_query(sub { '' });
$storage->_do_query(sub { [] });
is_deeply \@LOG, [], 'an empty answer runs nothing';

for my $bad (+{ sql => 'select 5' }, bless({}, 'Some::Object')) {
  throws_ok { $storage->_do_query(sub { $bad }) }
    qr/on_connect_do.*do_sql|do_sql.*on_connect_do/s,
    'a ' . ref($bad) . ' answer is refused naming on_connect_do/do_sql';
  unlike $@, qr/as an ARRAY ref/, '... not as the raw strict-refs error';
}
is_deeply \@LOG, [], '... and nothing ran';

# --- through the connection actions --------------------------------------

@LOG = ();
$storage->on_connect_do([ 'select 6', sub { 'select 7' } ]);
$storage->_do_connection_actions(connect_call_ => $_)
  for $storage->_parse_connect_do('on_connect_do');
is_deeply [ map $_->[0], @LOG ], [ 'select 6', 'select 7' ],
  'on_connect_do array element: code reference answering a string';

@LOG = ();
$storage->on_connect_do(sub { 'select 8' });
$storage->_do_connection_actions(connect_call_ => $_)
  for $storage->_parse_connect_do('on_connect_do');
is_deeply \@LOG, [],
  'the top-level code reference of on_connect_do keeps its answer ignored';

@LOG = ();
$storage->on_disconnect_do([ sub { 'select 9' } ]);
$storage->_do_connection_actions(disconnect_call_ => $_)
  for $storage->_parse_connect_do('on_disconnect_do');
is_deeply [ map $_->[0], @LOG ], [ 'select 9' ],
  'on_disconnect_do array element: code reference answering a string';

$storage->on_connect_do([ sub { { not => 'sql' } } ]);
throws_ok {
  $storage->_do_connection_actions(connect_call_ => $_)
    for $storage->_parse_connect_do('on_connect_do');
} qr/on_connect_do/, 'on_connect_do with a hash reference answer: refused, naming it';

# --- replay on a pool connection -----------------------------------------

my @POOL;
my $runner = sub { push @POOL, [ @_ ] };

$storage->on_connect_do([ 'select 10', sub { 'select 11' } ]);
$storage->on_connect_call(undef);
$storage->on_disconnect_do([ sub { 'select 12' } ]);
$storage->on_disconnect_call(undef);

@LOG = ();
$storage->_run_pool_connect_actions($runner);
$storage->_run_pool_disconnect_actions($runner);
is_deeply [ map $_->[0], @POOL ], [ 'select 10', 'select 11', 'select 12' ],
  'the pool replay runs the string answer on the pool connection';
is_deeply \@LOG, [], '... and not on the owning storage\'s own handle';

done_testing;
