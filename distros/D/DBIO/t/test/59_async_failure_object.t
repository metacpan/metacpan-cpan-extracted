use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed);

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::Future::Immediate ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::Exception::Server ();

# karr k335 (from dbio-postgresql-ev k74). The Future of a statement the server
# refused used to fail with one string: the SQLSTATE stood nowhere a caller
# could read it, and a lc_messages=de_DE server made the text unusable to
# tell 40001 / 40P01 / 23505 / 57014 apart. The contract (ADR 0062): a
# transport fails the Future with a DBIO::Exception::Server -- sqlstate,
# constraint, table, detail -- that stringifies to the text the string had.
#
# What this file pins is that core hands the object on as the SAME object:
# refaddr equal at the caller, directly, through txn_do_async (awaited,
# unawaited and returned statements, and a transaction whose coderef died with
# it) and through a pipeline, alone and inside a transaction. Where core
# prepends text ("BEGIN failed: ...", "COMMIT failed: ...", "Transaction
# aborted: ... Rollback failed: ...") the text is unchanged and an object stays
# an object: a derived copy carrying `context` (decision 2026-10-12).

{
  package K335::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K335::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K335::Conn->new(++$_[0]->{_next_id}) }
}

# One server error per name a statement carries. The fake wire answers the
# same object every time it is asked, so the test can compare addresses.
my %ERROR = (
  Duplicate => DBIO::Exception::Server->new(
    message    => qq{ERROR:  duplicate key value violates unique constraint "artist_name_key"\n},
    sqlstate   => '23505',
    constraint => 'artist_name_key',
    table      => 'artist',
    detail     => 'Key (name)=(Duplicate) already exists.',
  ),
  Deadlock => DBIO::Exception::Server->new(
    message  => "ERROR:  deadlock detected\n",
    sqlstate => '40P01',
  ),
);

{
  package K335::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { $_[0]->{future_class} || 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    return $_[0]->{pool} ||= K335::Pool->new(
      conninfo     => 'fake',
      size         => 2,
      future_class => $_[0]->future_class,
    );
  }

  # The pooled path is covered elsewhere; this file is about what core does
  # with the failure it is handed, so the fake answers without a pool.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    return $self->_answer($sql, $bind);
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->_answer($sql, $bind);
  }

  sub _answer {
    my ($self, $sql, $bind) = @_;
    my $fc = $self->future_class;
    return $fc->fail("no BEGIN for you\n") if $sql eq 'BEGIN' && $self->{fail_begin};
    return $fc->fail($ERROR{Deadlock}) if $sql eq 'BEGIN' && $self->{fail_begin_object};
    return $fc->fail($ERROR{Deadlock}) if $sql eq 'COMMIT' && $self->{fail_commit};
    return $fc->fail("connection reset\n") if $sql eq 'COMMIT' && $self->{fail_commit_text};
    return $fc->fail("ROLLBACK refused\n") if $sql eq 'ROLLBACK' && $self->{fail_rollback};
    return $fc->fail($ERROR{Deadlock}) if $sql eq 'ROLLBACK' && $self->{fail_rollback_object};
    return $fc->done unless $sql =~ /^(?:INSERT|UPDATE)/;
    my @values = map { ref $_ eq 'ARRAY' ? $_->[-1] : $_ } @{ $bind || [] };
    for my $name (sort keys %ERROR) {
      return $fc->fail($ERROR{$name}) if grep { defined && $_ eq $name } @values;
    }
    return $fc->done({ artistid => 1 }) if $sql =~ /^INSERT/;
    return $fc->done(1);
  }

  sub _pipeline_enter { 1 }
  sub _pipeline_exit  { 1 }
  sub _pipeline_sync  { return $_[0]->future_class->done }
}

sub new_backend {
  my (%knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K335::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

# The failure of a Future as the very value it failed with, taken through a
# catch callback -- the form a caller writes.
sub failure_of {
  my ($f) = @_;
  my @got;
  $f->catch(sub { @got = @_; return });
  return $got[0];
}

# What ->get throws.
sub thrown_by {
  my ($f) = @_;
  return eval { $f->get; 1 } ? undef : $@;
}

sub arrives_as_the_object {
  my ($error, $want, $label) = @_;
  ok blessed($error) && $error->isa('DBIO::Exception::Server'),
    "$label: the failure is a DBIO::Exception::Server"
    or return;
  is refaddr($error), refaddr($want),
    "$label: it is the same object the transport failed with";
  is $error->sqlstate, $want->sqlstate, "$label: sqlstate is readable";
  is "$error", $want->{msg}, "$label: it stringifies to the text";
  ok scalar($error =~ /deadlock|duplicate key/),
    "$label: and still matches a regex";
}

# --- the class itself -------------------------------------------------------
{
  my $e = $ERROR{Duplicate};
  isa_ok $e, 'DBIO::Exception';
  is $e->sqlstate,   '23505',           'sqlstate';
  is $e->constraint, 'artist_name_key', 'constraint';
  is $e->table,      'artist',          'table';
  like $e->detail, qr/already exists/, 'detail';
  is "$e", qq{ERROR:  duplicate key value violates unique constraint "artist_name_key"\n},
    'stringifies to the message, untouched';
  ok $e eq qq{ERROR:  duplicate key value violates unique constraint "artist_name_key"\n},
    'eq compares as the string';
  is $ERROR{Deadlock}->constraint, undef, 'a field not given is undef';

  eval { DBIO::Exception::Server->new(sqlstate => '40001') };
  like "$@", qr/needs a message/, 'a message is required';
  eval { DBIO::Exception::Server->new(message => '0') };
  like "$@", qr/needs a message/, 'a false message is refused';
  eval { DBIO::Exception::Server->new(message => 'x', sqlstat => '40001') };
  like "$@", qr/unknown argument\(s\) sqlstat/, 'an unknown argument is refused';

  eval { DBIO::Exception::Server->throw(message => "boom\n", sqlstate => '57014') };
  isa_ok $@, 'DBIO::Exception::Server', 'throw dies with the object';
  is "$@", "boom\n", 'throw adds nothing to the text';
}

# --- directly, on a statement ----------------------------------------------
for my $fc (qw(DBIO::Test::Future DBIO::Future::Immediate)) {
  my $backend = new_backend(future_class => $fc);
  my $f = $backend->insert_async('artist', { name => 'Duplicate' });
  ok $f->is_failed, "$fc direct: the statement fails";
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, "$fc direct, catch");
  arrives_as_the_object(thrown_by($f),  $ERROR{Duplicate}, "$fc direct, get");
}

# --- through txn_do_async ---------------------------------------------------
{
  # an awaited statement, returned from the coderef
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    return $_[0]->insert_async('artist', { name => 'Duplicate' });
  });
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, 'txn, returned statement');
  is_deeply [ map { /^(\w+)/ } @{ $backend->{captured} } ],
    [ qw(BEGIN INSERT ROLLBACK) ],
    'txn, returned statement: rolled back';
}
{
  # a statement nobody awaited: the recorder keeps it for the commit decision
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    $_[0]->insert_async('artist', { name => 'Deadlock' });
    return 'queued';
  });
  arrives_as_the_object(failure_of($f), $ERROR{Deadlock}, 'txn, unawaited statement');
  arrives_as_the_object(thrown_by($f),  $ERROR{Deadlock}, 'txn, unawaited statement, get');
}
{
  # the coderef dies with it
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub { die $ERROR{Duplicate} });
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, 'txn, coderef dies with it');
}
{
  # the coderef handled the statement's failure and went on
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    return $_[0]->insert_async('artist', { name => 'Duplicate' })
      ->catch(sub { return 'recovered' });
  });
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, 'txn, handled statement');
}
{
  # a statement chained with then: the failure passes the chain
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    return $_[0]->insert_async('artist', { name => 'Duplicate' })
      ->then(sub { 'not reached' });
  });
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, 'txn, chained statement');
}

# --- through a pipeline -----------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->pipeline(sub {
    my ($batch) = @_;
    $batch->insert_async('artist', { name => 'Miles' });
    return $batch->insert_async('artist', { name => 'Duplicate' });
  });
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, 'pipeline');
}
{
  # the batch coderef dies with it
  my $backend = new_backend();
  my $f = $backend->pipeline(sub { die $ERROR{Deadlock} });
  arrives_as_the_object(failure_of($f), $ERROR{Deadlock}, 'pipeline, batch dies with it');
}
{
  # a pipeline inside a transaction, returned
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      return $_[0]->insert_async('artist', { name => 'Duplicate' });
    });
  });
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, 'pipeline in txn');
}
{
  # a pipeline inside a transaction, not awaited
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->pipeline(sub {
      return $_[0]->insert_async('artist', { name => 'Duplicate' });
    });
    return 'queued';
  });
  arrives_as_the_object(failure_of($f), $ERROR{Duplicate}, 'pipeline in txn, unawaited');
}

# --- where core prepends text: the object stays, with a context -------------
# Maintainer decision 2026-10-12 (ADR 0062): the failure of a BEGIN, COMMIT or
# ROLLBACK that is a Server object stays an object -- a derived copy of the same
# class and fields, with `context` set -- and stringifies with the prefix, so
# $@ =~ /COMMIT failed/ and eq keep working. A failure that is no object stays
# the string it was.

# the derived copy: not the object the transport failed with, everything else
# of it unchanged
sub derived_copy_of {
  my ($error, $original, $context, $text, $name) = @_;
  ok blessed($error) && $error->isa('DBIO::Exception::Server'),
    "$name: a DBIO::Exception::Server";
  isnt refaddr($error), refaddr($original), "$name: a derived copy, not the object itself";
  is ref($error), ref($original), "$name: same class";
  is $error->context, $context, "$name: context";
  is $error->$_, $original->$_, "$name: $_ unchanged" for qw(sqlstate constraint table detail);
  is "$error", $text, "$name: stringifies with the prefix";
  is $error, $text, "$name: eq the prefixed text";
  ok !defined $original->context, "$name: the transport's object itself is untouched";
}

{
  my $backend = new_backend(fail_commit => 1);
  my $f = $backend->txn_do_async(sub { return 'ok' });
  derived_copy_of(failure_of($f), $ERROR{Deadlock}, 'COMMIT',
    "COMMIT failed: ERROR:  deadlock detected\n", 'COMMIT failed');
}
{
  # a pipeline ran in the transaction, then the COMMIT was refused
  my $backend = new_backend(fail_commit => 1);
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      return $_[0]->insert_async('artist', { name => 'Miles' });
    });
  });
  derived_copy_of(failure_of($f), $ERROR{Deadlock}, 'COMMIT',
    "COMMIT failed: ERROR:  deadlock detected\n", 'COMMIT failed after a pipeline');
}
{
  my $backend = new_backend(fail_commit => 1);
  my $f = $backend->txn_do_async(sub { return 'ok' });
  like failure_of($f), qr/^COMMIT failed: /, 'COMMIT failed: =~ on the object still matches';
}
{
  my $backend = new_backend(fail_commit_text => 1);
  my $f = $backend->txn_do_async(sub { return 'ok' });
  my $error = failure_of($f);
  ok !ref $error, 'COMMIT failed with a string: stays a string';
  is $error, "COMMIT failed: connection reset\n", 'COMMIT failed with a string: the text';
}
{
  my $backend = new_backend(fail_begin_object => 1);
  my $f = $backend->txn_do_async(sub { return 'ok' });
  derived_copy_of(failure_of($f), $ERROR{Deadlock}, 'BEGIN',
    "BEGIN failed: ERROR:  deadlock detected\n", 'BEGIN failed');
}
{
  my $backend = new_backend(fail_begin => 1);
  my $f = $backend->txn_do_async(sub { return 'ok' });
  is failure_of($f), "BEGIN failed: no BEGIN for you\n",
    'BEGIN failed with a string: the text is what it was';
  ok !ref failure_of(new_backend(fail_begin => 1)->txn_do_async(sub { 'ok' })),
    'BEGIN failed with a string: still a string';
}
{
  # ROLLBACK refused with a string: the DBIO::Exception it was
  my $backend = new_backend(fail_rollback => 1);
  my $f = $backend->txn_do_async(sub {
    return $_[0]->insert_async('artist', { name => 'Duplicate' });
  });
  my $error = failure_of($f);
  ok !(blessed($error) && $error->isa('DBIO::Exception::Server')),
    'Rollback failed with a string: stays the DBIO::Exception it was, not an object';
  like $error, qr/Transaction aborted: ERROR:  duplicate key value .* Rollback failed: ROLLBACK refused/s,
    'Rollback failed with a string: the text is what it was';
}
{
  # ROLLBACK refused with a Server object: kept, as a copy with context ROLLBACK
  my $backend = new_backend(fail_rollback_object => 1);
  my $f = $backend->txn_do_async(sub {
    return $_[0]->insert_async('artist', { name => 'Duplicate' });
  });
  my $error = failure_of($f);
  ok blessed($error) && $error->isa('DBIO::Exception::Server'), 'Rollback failed: an object';
  is $error->context, 'ROLLBACK', 'Rollback failed: context';
  is $error->sqlstate, '40P01', 'Rollback failed: the ROLLBACK error\'s sqlstate';
  like "$error", qr/Transaction aborted: ERROR:  duplicate key value .* Rollback failed: ERROR:  deadlock detected/s,
    'Rollback failed: the text is what it was';
}

# --- the class: context and with_context ------------------------------------
{
  my $e = $ERROR{Duplicate};
  ok !defined $e->context, 'context is undef on a fresh object';
  my $c = $e->with_context('COMMIT', 'COMMIT failed: ' . $e);
  is $c->context, 'COMMIT', 'with_context sets context';
  is "$c", 'COMMIT failed: ' . $e, 'with_context sets the message';
  my $d = $e->with_context('BEGIN');
  is "$d", "$e", 'with_context without a message keeps the text';
  eval { $e->with_context(undef) };
  isa_ok $@, 'DBIO::Exception', 'with_context needs a context';
}

done_testing;
