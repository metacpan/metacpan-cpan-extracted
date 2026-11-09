use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::DBI::NoBindVars;

# ADR 0040 section 6: DBIO::Storage::DBI::_prepare_rendered --
# _execute_rendered stopped one verb short.
#
# ADR 0040 made one rule binding: every statement an _explain_query override
# issues goes through the storage's statement path, because owning the
# execution is what lets a driver lose tracing (and therefore
# redact_bind_value, ADR 0025), dbh_do retry, NoBindVars interpolation and the
# read handler in one step. Firebird has no statement for that rule to apply
# to -- its plan is a property of the PREPARED statement
# (isc_info_sql_get_plan, read with $sth->func('ib_plan')), and
# _execute_rendered prepares
# AND executes, so there is nothing to route. Rather than write an
# engine-named hole into a rule whose whole value is being exceptionless, the
# path itself is exposed one step earlier.
#
# This file is about the SEAM. The rule it serves is pinned in
# t/helpers/explain.t sections 6 and 7, in the driver-shaped form.
#
# Everything here runs against stub handles -- no database, per house rules.
# The stubs count what was called on them, which is the whole point: the one
# thing separating this seam from _execute_rendered is an execute that must
# NOT happen, and that is invisible on a fake storage which never executes
# anything anyway.

# ---- counting stub handles ------------------------------------------------

{
  package My::Counting::Sth;
  sub new   { bless { bound => [], executed => 0, finished => 0 }, shift }
  sub bind_param       { my $s = shift; push @{$s->{bound}}, [ @_ ]; 1 }
  sub bind_param_inout { my $s = shift; push @{$s->{bound}}, [ @_ ]; 1 }
  sub execute          { $_[0]{executed}++; '0E0' }
  sub finish           { $_[0]{finished}++; 1 }
  sub errstr           { undef }
  sub err              { undef }

  package My::Counting::Dbh;
  sub new { bless { prepared => [], cached => 0, sths => [], die_once => 0 }, shift }
  sub _make {
    my ($self, $sql) = @_;
    if ($self->{die_once}) {
      $self->{die_once} = 0;
      die "server has gone away\n";
    }
    push @{ $self->{prepared} }, $sql;
    my $sth = My::Counting::Sth->new;
    push @{ $self->{sths} }, $sth;
    return $sth;
  }
  sub prepare        { my ($s, $sql) = @_; $s->_make($sql) }
  sub prepare_cached { my ($s, $sql) = @_; $s->{cached}++; $s->_make($sql) }
  sub quote          { my ($s, $v) = @_; defined $v ? "'$v'" : 'NULL' }
  sub errstr         { undef }

  package My::Counting::Storage;
  our @ISA = ('DBIO::Storage::DBI');
  use mro 'c3';
  sub _populate_dbh    { }
  sub _dbh             { $_[0]->{stub_dbh} }
  sub _get_dbh         { $_[0]->{stub_dbh} }
  sub connected        { $_[0]->{stub_connected} }
  sub _seems_connected { $_[0]->{stub_connected} }

  # DBIO::Storage::DBI::NoBindVars over the same stub, to prove the
  # pre-execution reshaping hook is reached on this path too.
  package My::Counting::NoBindVars::Storage;
  our @ISA = ('DBIO::Storage::DBI::NoBindVars', 'My::Counting::Storage');
  use mro 'c3';
}
$INC{'My/Counting/Storage.pm'}             = __FILE__;
$INC{'My/Counting/NoBindVars/Storage.pm'}  = __FILE__;

sub build_storage {
  my $class   = shift || 'My::Counting::Storage';
  my $storage = $class->new;
  $storage->{stub_dbh}       = My::Counting::Dbh->new;
  $storage->{stub_connected} = 1;
  $storage->{_driver_determined} = 1;
  return $storage;
}

my $BIND = [ [ { dbic_colname => 'password' }, 'hunter2' ] ];
my $SQL  = 'SELECT plan FROM t WHERE secret = ?';

# --- 1. THE POINT: it prepares and it does not execute ---------------------

{
  my $storage = build_storage();

  my $sth = $storage->_prepare_rendered($SQL, $BIND);

  isa_ok $sth, 'My::Counting::Sth', 'the seam hands back the live statement handle';
  is_deeply $storage->{stub_dbh}{prepared}, [ $SQL ],
    'the statement was prepared on the handle the storage owns';
  is $sth->{executed}, 0,
    'and it was NOT executed -- the one thing this seam is for '
  . '(Firebird reads func(\'ib_plan\') off a statement that never runs)';

  is_deeply $sth->{bound}, [ [ 1, 'hunter2', undef ] ],
    'the binds are bound, so the caller receives a handle ready to execute';
}

# --- 2. the control: _execute_rendered on the same stub DOES execute -------
#
# Section 1's assertion is only worth something if it can fail. Same storage,
# same statement, same stub -- the sibling method, one verb further.

{
  my $storage = build_storage();

  my (undef, $sth) = $storage->_execute_rendered($SQL, $BIND);

  is $sth->{executed}, 1,
    '_execute_rendered executes the statement it prepared '
  . '(so the "was not executed" assertion above discriminates)';
}

# --- 3. tracing survives, and with it redact_bind_value (ADR 0025) --------
#
# This is the guarantee the seam exists to preserve. A driver reaching for
# $self->dbh to prepare gets none of it, and the bind values it leaks are the
# WHERE-clause values of the user's own query.

{
  my $storage = build_storage();

  $storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname eq 'password' ? '[redacted]' : $value;
  });

  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  $storage->_prepare_rendered($SQL, $BIND);
  $storage->debug(0);
  $storage->debugcb(undef);

  ok scalar(grep { /^\Q$SQL\E/ } @traced),
    'the prepared statement reaches the trace sink';
  ok scalar(grep { /\[redacted\]/ } @traced),
    '... with redact_bind_value applied to its binds (ADR 0025)';
  ok !scalar(grep { /hunter2/ } @traced),
    '... and the raw value never got there';
}

# --- 4. dbh_do retry over a dropped connection ----------------------------
#
# Named as a surviving guarantee in the POD, so it is asserted rather than
# claimed. A prepare is a better citizen under retry than an execute: re-running
# one leaves nothing behind, which is exactly what dbh_do asks of its callers.

{
  my $storage = build_storage();
  $storage->{stub_dbh}{die_once} = 1;
  $storage->{stub_connected}     = 0;   # what makes the retry_handler fire

  my $sth = $storage->_prepare_rendered($SQL, $BIND);

  isa_ok $sth, 'My::Counting::Sth',
    'a prepare that died on a dropped connection was retried by dbh_do';
  is_deeply $storage->{stub_dbh}{prepared}, [ $SQL ],
    '... and the second attempt is the one that produced the handle';
}

# --- 5. _prep_rendered_for_execute is reached (NoBindVars) -----------------
#
# Without it an engine with no usable placeholders would be handed a statement
# core did not build through sql_maker with its ? intact.

{
  my $storage = build_storage('My::Counting::NoBindVars::Storage');

  my $sth = $storage->_prepare_rendered($SQL, $BIND);

  is_deeply $storage->{stub_dbh}{prepared},
    [ q{SELECT plan FROM t WHERE secret = 'hunter2'} ],
    'NoBindVars interpolated the binds before the prepare, like it does '
  . 'before an execute';
  is_deeply $sth->{bound}, [],
    '... leaving nothing to bind on the handle';
}

# --- 6. the statement cache is used, unless the storage disables it -------
#
# Documented as a thing the caller must know: the handle can come out of DBI's
# prepare_cached pool, so it is to be used and let go, not held across other
# statements.

{
  my $storage = build_storage();
  $storage->_prepare_rendered($SQL, []);
  is $storage->{stub_dbh}{cached}, 1, 'prepare_cached by default';

  my $uncached = build_storage();
  $uncached->disable_sth_caching(1);
  $uncached->_prepare_rendered($SQL, []);
  is $uncached->{stub_dbh}{cached}, 0,
    'disable_sth_caching reaches this path too (it is the same _prepare_sth)';
}

# --- 7. the fake storage answers the seam --------------------------------
#
# Core's suite is mock-only, and so is every driver's offline suite: the seam
# has to be usable there or a driver cannot test its _explain_query at all.
# DBIO::Test::Storage captures a prepare like it captures an execute, and marks
# it -- op 'prepare' -- which is the only way the two are distinguishable on a
# storage that never executes anything.

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  $storage->reset_captured;
  my $sth = $storage->_prepare_rendered('SELECT 1 FROM "artist" WHERE "name" = ?',
    [ [ { dbic_colname => 'name' }, 'foo' ] ]);

  ok $sth, 'the fake storage answers _prepare_rendered with a handle';

  my @captured = $storage->captured_queries;
  is scalar @captured, 1, 'the prepared statement was captured';
  is $captured[0]{op}, 'prepare',
    'and it is marked as a prepare, not a select';
  is $captured[0]{sql}, 'SELECT 1 FROM "artist" WHERE "name" = ?',
    'the SQL is captured verbatim';
}

done_testing;
