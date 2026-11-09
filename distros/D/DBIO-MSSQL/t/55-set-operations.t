use strict;
use warnings;
use Test::More;
use Test::Exception;
use mro;
use DBIO::Test ':DiffSQL';

# Offline test of _set_operation_keyword (ADR 0039). The hook is a static
# class fact by contract -- no $dbh, no version probe -- so a test that needs
# a database would be testing the wrong thing.

use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::MSSQL::Storage',
  no_deploy    => 1,
  quote_names  => 1,
);
my $storage = $schema->storage;

# --- the four SQL Server has, inherited from the base map ----------------

my %ansi = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  except        => 'EXCEPT',
);

is( $storage->_set_operation_keyword($_), $ansi{$_},
  "$_ falls through to next::method and keeps the ANSI spelling" )
  for sort keys %ansi;

# --- the two it does not have, refused ------------------------------------

for my $op (qw/intersect_all except_all/) {
  throws_ok { $storage->_set_operation_keyword($op) }
    qr/SQL Server has no \Q$op\E/,
    "$op is refused, naming the engine and the operation";

  throws_ok { $storage->_set_operation_keyword($op) }
    qr/unconditional/,
    '... and says the refusal is unconditional (ADR 0039 section 7)';
}

# The refusal must carry the engine fact, not just a "no". ADR 0039 section 2
# puts the message in the driver precisely because core cannot write this.
throws_ok { $storage->_set_operation_keyword('except_all') }
  qr/no ALL variant/,
  'the message states why: EXCEPT/INTERSECT take no ALL on this engine';

throws_ok { $storage->_set_operation_keyword('except_all') }
  qr/->except\(\)/,
  '... and names except() as the nearest operation';

throws_ok { $storage->_set_operation_keyword('except_all') }
  qr/not a substitute/,
  '... while refusing to pass it off as an equivalent (ADR 0039 section 3)';

# --- an unknown op is still a core programming error, not our business ----
#
# This is what proves the override hands everything it has no opinion about
# to next::method rather than owning the whole map.

throws_ok { $storage->_set_operation_keyword('sideways_join') }
  qr/Unknown set operation/,
  'an unrecognised operation reaches core\'s base throw through next::method';

# ADR 0039 (addendum 2026-08-04): an undefined operation is core's
# programming error too, but only if the override hands it down before
# comparing it. Compared first, `$op eq ...` warns on undef before core throws.
{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  throws_ok { $storage->_set_operation_keyword(undef) }
    qr/Unknown set operation|set operation/i,
    'an undefined operation reaches core\'s base throw';
  is_deeply \@warn, [], '... without an uninitialized-value warning first';
}

# --- the rebless targets inherit both halves ------------------------------
#
# Also a tripwire for a cross-repo hazard, not just an inheritance check.
# DBIO::MSSQL::Storage::Sybase is @ISA (DBIO::Sybase::Storage,
# DBIO::MSSQL::Storage) under c3, so a _set_operation_keyword added to
# DBIO::Sybase::Storage would win here -- and this class talks DBD::Sybase to
# *Microsoft SQL Server*, not to Sybase ASE, so an ASE engine fact would be
# the wrong answer on this path. If this fails after a dbio-sybase change,
# that is the finding, not a stale assertion.
#
# What this can and cannot see (karr k25, raised from dbio-sybase k30). It
# cannot fail before dbio-sybase declares the hook -- no test on this side of
# the family can, the offending sub has to exist first. What it must not do is
# read green while not having run at all, and that is what the old form did:
# DBIO::MSSQL::Storage::Sybase was appended to the loop only when it loaded,
# so on a box without DBIO::Sybase (an optional dep) the iteration vanished
# with no trace in the TAP and the run was indistinguishable from one that
# checked. Hence the explicit skip below.
#
# Hence also the definer assertion. Comparing coderefs answers "wrong" with
# two CODE(0x...); the first class along the c3 linearisation that actually
# defines the sub NAMES the offender. That form stays sharp wherever in the
# dbio-sybase tree such an override lands, without this repo hardcoding a
# class name out of a dist it does not control -- which is why it is here
# rather than the isnt() against DBIO::Sybase::Storage::ASE the ticket
# suggested. ASE is not in this linearisation at all, so that comparison
# could never have failed; the dangerous class is DBIO::Sybase::Storage,
# which is.

sub first_definer {
  my ($class, $method) = @_;
  no strict 'refs';
  return( (grep { defined &{"${_}::${method}"} }
             @{ mro::get_linear_isa($class) })[0] );
}

sub hook_is_ours {
  my ($class) = @_;

  is( $class->can('_set_operation_keyword'),
    DBIO::MSSQL::Storage->can('_set_operation_keyword'),
    "$class resolves the hook to the MSSQL override" );

  is( first_definer($class, '_set_operation_keyword'), 'DBIO::MSSQL::Storage',
    "... and DBIO::MSSQL::Storage is the class that supplies it" );
}

hook_is_ours('DBIO::MSSQL::Storage::ODBC');

SKIP: {
  skip 'DBIO::Sybase not installed (optional dep), so the cross-dist half of '
     . 'this tripwire did NOT run', 2
    unless eval { require DBIO::MSSQL::Storage::Sybase; 1 };

  hook_is_ours('DBIO::MSSQL::Storage::Sybase');
}

# --- end to end: the keyword reaches the SQL, the refusal reaches nothing --

my $a = $schema->resultset('Artist')->search({ name => 'a' });
my $b = $schema->resultset('Artist')->search({ name => 'b' });

my $cols = '[me].[artistid], [me].[name], [me].[rank], [me].[charfield]';

for my $op (sort keys %ansi) {
  is_same_sql_bind(
    $a->$op($b)->as_query,
    "( SELECT $cols FROM (
         SELECT $cols FROM [artist] [me] WHERE ( [name] = ? )
         $ansi{$op}
         SELECT $cols FROM [artist] [me] WHERE ( [name] = ? )
       ) [me] )",
    [ map { [ { sqlt_datatype => 'varchar', sqlt_size => 100,
                dbic_colname => 'name' } => $_ ] } qw/a b/ ],
    "$op emits $ansi{$op} between the operands",
  );
}

# ADR 0039 section 4: the keyword is resolved before a single operand is
# rendered, so a refused operation throws at query-build time and issues no
# SQL at all. Asserting the empty query log is the only way to tell that apart
# from throwing after the fragment was already built.
for my $op (qw/intersect_all except_all/) {
  $storage->reset_captured;

  throws_ok { $a->$op($b)->as_query } qr/SQL Server has no \Q$op\E/,
    "\$rs->$op throws while the query is being built";

  is scalar($storage->captured_queries), 0, '... having issued no SQL';
}

done_testing;
