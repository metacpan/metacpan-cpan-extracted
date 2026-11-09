use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Util ();
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# An async ResultSet call answers with a Future. A runtime failure while the
# statement is built on the pooled path -- the synchronous owner cannot connect
# for its sql_maker -- arrives as a failed Future of the storage's future_class;
# misuse (an expired bound context, a connection without an async mode) is an
# exception at the call. Mock storage only, no real database.

{
  package Test::BuildPool;
  sub new { bless {}, shift }
  sub acquire     { DBIO::Test::Future->done('CONN') }
  sub acquire_txn { DBIO::Test::Future->done('CONN') }
  sub release     { 1 }
  sub shutdown    { 1 }
}

{
  package Test::BuildBackend;
  use base 'DBIO::Storage::Async';

  sub new { my ($c, $s) = @_; my $self = $c->SUPER::new($s); $self->{captured} = []; $self }
  sub future_class    { 'DBIO::Test::Future' }
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= Test::BuildPool->new }
  sub _query_async {
    my ($self, $sql) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->future_class->done;
  }
  sub _query_async_pinned { my ($self, $conn, @rest) = @_; $self->_query_async(@rest) }
  sub _pipeline_enter { 1 }
  sub _pipeline_exit  { 1 }
  sub _pipeline_sync  { $_[0]->future_class->done }
}

DBIO::Storage::DBI->register_async_mode( build_failure => 'Test::BuildBackend' );

my $SECRET = 's3cr3t-pw-403';

sub wired_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('build_failure');
  delete $schema->storage->{_async_storage_obj};
  my $backend = $schema->storage->_async_storage;
  return ($schema, $backend);
}

# The sync owner cannot connect for its sql_maker; its error is masked the way
# every connect error is. Returns the restore closure.
sub unreachable_owner {
  my ($schema) = @_;
  my $class = ref $schema->storage;
  no strict 'refs';
  no warnings 'redefine';
  my $orig = \&{"${class}::sql_maker"};
  *{"${class}::sql_maker"} = sub {
    die DBIO::Util::mask_connect_secrets(
      "connection to dbi:Pg:host=nowhere failed (password $SECRET)\n",
      [ 'dbi:Pg:host=nowhere', 'u', $SECRET, {} ],
    );
  };
  return sub { no strict 'refs'; no warnings 'redefine'; *{"${class}::sql_maker"} = $orig };
}

for my $call (qw(count_async all_async)) {
  my ($schema, $backend) = wired_schema();
  my $restore = unreachable_owner($schema);

  my $f;
  lives_ok { $f = $schema->resultset('Artist')->$call }
    "$call does not throw when the statement cannot be built";
  $restore->();

  ok $f && $f->is_failed, "$call: the Future is failed" or next;
  isa_ok $f, 'DBIO::Test::Future', "$call: a Future of the storage's future_class";

  my $error;
  $f->catch(sub { ($error) = @_; return });
  like "$error", qr/connection to dbi:Pg:host=nowhere failed/, "$call: the message is the one thrown";
  unlike "$error", qr/\Q$SECRET\E/, "$call: the message carries no password";
  is scalar @{ $backend->{captured} }, 0, "$call: nothing reached the backend";
}

# Misuse stays an exception at the call.
{
  my ($schema, $backend) = wired_schema();
  my $bound;
  my $txn = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $bound = $schema->resultset('Artist')->with_context($ctx);
    return DBIO::Test::Future->done('finished');
  });
  is scalar $txn->get, 'finished', 'transaction ends';

  throws_ok { $bound->count_async } qr/no longer active/,
    'a bound expired context still throws at the call (count_async)';
  throws_ok { $bound->all_async } qr/no longer active/,
    'a bound expired context still throws at the call (all_async)';
}

{
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode(undef);
  throws_ok { $schema->resultset('Artist')->count_async } qr/not an async connection/,
    'a connection without an async mode still throws at the call';
}

done_testing;
