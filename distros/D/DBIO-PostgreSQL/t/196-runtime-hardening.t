use strict;
use warnings;
use Test::More;

# OFFLINE test: the small runtime hardenings of karr k155.
#
# WHY: a name or a text a declaration, a caller or a broker supplies must reach
# the server as what it is -- a value as a bind, an identifier in its plain
# form -- and a message never repeats the values of a row. What this file
# claims:
#   1. the sequence of an auto_nextval column is a bind cast to regclass,
#      sent through the rendered-statement path (captured with its bind),
#      never a literal in the statement text; only NEXTVAL and CURRVAL are
#      functions of the protocol;
#   2. a savepoint name is 1 to 63 letters, digits and underscores, beginning
#      with a letter or underscore; any other is refused before DBD::Pg sees
#      it, and the message names the form, never the value;
#   3. a connection parameter key of a broker's answer is a libpq parameter
#      name, else the future_io transport refuses it naming the key;
#   4. the values of Key (cols)=(values) and Failing row contains (values)
#      are *** in the detail field and in the DETAIL line of the message,
#      for the sync storage and the future_io transport; column names, the
#      constraint and the table stay.

use DBIO::Test;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Util ();

sub new_storage {
  return DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::PostgreSQL::Storage',
  )->storage;
}

# --- 1. sequence ------------------------------------------------------------
{
  my $storage = new_storage;
  my $evil = q{s'); DROP TABLE t; --};
  $storage->mock(qr/nextval/i, [ [ 7 ] ]);
  $storage->reset_captured;

  is $storage->_sequence_fetch('NEXTVAL', $evil), 7, 'the value of the sequence comes back';

  my @q = $storage->captured_queries;
  is scalar @q, 1, 'one statement';
  is $q[0]{sql}, 'SELECT nextval(?::regclass)', '... the sequence is a placeholder cast to regclass';
  unlike $q[0]{sql}, qr/DROP/, '... and no part of the name is in the statement';
  is_deeply [ map { $_->[1] } @{ $q[0]{bind} } ], [ $evil ], '... it is the bind';

  $storage->reset_captured;
  $storage->mock(qr/currval/i, [ [ 3 ] ]);
  $storage->_sequence_fetch('CURRVAL', \'public.s');
  @q = $storage->captured_queries;
  is $q[0]{sql}, 'SELECT currval(?::regclass)', 'CURRVAL is the other function of the protocol';
  is_deeply [ map { $_->[1] } @{ $q[0]{bind} } ], [ 'public.s' ], '... a scalar ref name is its text';

  ok !eval { $storage->_sequence_fetch('nextval(1); DROP TABLE t; select', 's'); 1 },
    'a function that is none of the two is refused';
}

# --- 2. savepoint names -----------------------------------------------------
{
  # the mock storage replaces the _exec_svp_* methods, so the driver's own
  # run against a handle that records what DBD::Pg would be asked
  package Fake::Dbh;
  sub new { bless { calls => [] }, shift }
  sub pg_savepoint   { push @{ $_[0]{calls} }, [ savepoint => $_[1] ] }
  sub pg_release     { push @{ $_[0]{calls} }, [ release   => $_[1] ] }
  sub pg_rollback_to { push @{ $_[0]{calls} }, [ rollback  => $_[1] ] }
}
{
  my $dbh = Fake::Dbh->new;
  my $storage = bless { _dbh => $dbh }, 'DBIO::PostgreSQL::Storage';
  $storage->_exec_svp_begin('sp_1');
  $storage->_exec_svp_release('sp_1');
  $storage->_exec_svp_rollback('sp_1');
  is_deeply $dbh->{calls}, [ [ savepoint => 'sp_1' ], [ release => 'sp_1' ], [ rollback => 'sp_1' ] ],
    'a plain name reaches DBD::Pg';
  $dbh->{calls} = [];
  for my $bad (q{x; DELETE FROM t; --}, 'with space', '1abc', '', 'a' x 64, undef) {
    for my $m (qw( _exec_svp_begin _exec_svp_release _exec_svp_rollback )) {
      my $ok = eval { $storage->$m($bad); 1 };
      my $err = "$@";
      ok !$ok, "$m refuses " . (defined $bad ? "'" . substr($bad, 0, 12) . "'" : 'undef');
      like $err, qr/letters, digits and underscores/, '... naming the form';
      unlike $err, qr/DELETE|with space/, '... and not the value' if defined $bad && length $bad;
    }
  }
  is_deeply $dbh->{calls}, [], 'DBD::Pg was asked for none of them';
  is $storage->_check_savepoint_name($_), $_, "'$_' is a savepoint name"
    for 'sp1', '_x', 'a' x 63, 'DBIO_SP_2';
}

# --- 3. broker keys ---------------------------------------------------------
SKIP: {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or skip 'DBIO::Async not installed -- future_io transport unavailable', 6;

  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);

  for my $key ('host;hostaddr', 'sslmode=disable', 'Host', '1x', 'a b') {
    my $ok = eval { $s->_pg_broker_conninfo_hash({ dbname => 'app', $key => '10.0.0.9' }); 1 };
    my $err = "$@";
    ok !$ok, "a key '$key' is refused";
    like $err, qr/\Q'$key'\E/, '... naming the key';
    unlike $err, qr/10\.0\.0\.9/, '... and not the value';
  }

  my $h = eval { $s->_pg_broker_conninfo_hash({ dbname => 'app', sslmode => 'verify-full', connect_timeout => 5 }) };
  is $h && $h->{dsn}, 'dbi:Pg:connect_timeout=5;dbname=app;sslmode=verify-full',
    'plain libpq parameter names go into the DSN' or diag $@;
}

# --- 4. detail values -------------------------------------------------------
{
  is DBIO::PostgreSQL::Util::mask_detail_values('Key (email)=(a@b.c) already exists.'),
    'Key (email)=(***) already exists.', 'a unique violation: value masked';
  is DBIO::PostgreSQL::Util::mask_detail_values('Key (a, b)=(1, x (y)) already exists.'),
    'Key (a, b)=(***) already exists.', '... several columns, parentheses in a value';
  is DBIO::PostgreSQL::Util::mask_detail_values('Key (lower(email::text))=(x) already exists.'),
    'Key (lower(email::text))=(***) already exists.', '... an expression key';
  is DBIO::PostgreSQL::Util::mask_detail_values('Key (id)=(5) is not present in table "users".'),
    'Key (id)=(***) is not present in table "users".', 'a foreign key violation: value masked, table stays';
  is DBIO::PostgreSQL::Util::mask_detail_values('Failing row contains (1, secret, null).'),
    'Failing row contains (***).', 'a check violation: the row is masked';
  is DBIO::PostgreSQL::Util::mask_detail_values('Process 1 waits for ShareLock'),
    'Process 1 waits for ShareLock', 'another detail is as it was';

  my $msg = qq{DBD::Pg::st execute failed: ERROR:  duplicate key value violates unique constraint "u"\n}
          . qq{DETAIL:  Key (email)=(a\@b.c) already exists.\n};
  my $masked = DBIO::PostgreSQL::Util::mask_error_details($msg);
  like $masked, qr/DETAIL:  Key \(email\)=\(\*\*\*\) already exists\./, 'the DETAIL line of a message is masked';
  like $masked, qr/unique constraint "u"/, '... the rest of the message stays';

  my $storage = new_storage;
  is $storage->_mask_error_values($msg, [], undef), $masked,
    'the storage hook (_mask_error_values) masks the DETAIL line as Util does';
  is $storage->_mask_error_values(undef, [], undef), undef, '... undef passes through';
  my $err = eval { $storage->_dbi_handle_error($msg, undef); 1 } ? '' : "$@";
  like $err, qr/Key \(email\)=\(\*\*\*\)/, 'the sync storage raises the masked message';
  unlike $err, qr/a\@b\.c/, '... without the value';
}

SKIP: {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or skip 'DBIO::Async not installed -- future_io transport unavailable', 2;
  my $err = eval {
    DBIO::PostgreSQL::Storage::Async::_pg_raise(
      qq{DBD::Pg::db pg_result failed: ERROR:  x\nDETAIL:  Key (id)=(1) already exists.});
    1 } ? '' : "$@";
  like $err, qr/Key \(id\)=\(\*\*\*\) already exists\./, 'the future_io transport raises the masked message';
  unlike $err, qr/=\(1\)/, '... without the value';
}

done_testing;
