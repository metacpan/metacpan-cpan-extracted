use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::Sybase; 1 } or plan skip_all => 'DBD::Sybase is not installed';
}

use DBIO::Sybase::Storage::ASE;

# OFFLINE half of ADR 0006 (core ADR 0075), t/120 is the live one. The ways an
# engine text reaches an exception or a warning without core's own error
# handler, and the contract of the hook itself.
#
# WHY IT MATTERS. A text the driver throws or carps on its own (the callback of
# the bulk path, the TEXT/IMAGE writer) bypasses core's handler; if it is not
# sent through the hook, the value of the row is in the log. Each case here is
# one of those paths with a stand-in for the client library: the value is in the
# text the library gives, and not in the text the caller gets.
#
# Nothing connects.

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $ASE = 'DBIO::Sybase::Storage::ASE';
sub storage { $ASE->new }

# --- the hook -------------------------------------------------------------

subtest '_mask_error_values: the contract' => sub {
  my $s = storage();

  is $s->_mask_error_values(undef, ['abcdefgh'], undef), undef, 'undef stays undef';
  my $ref = { text => 'x' };
  is $s->_mask_error_values($ref, [], undef), $ref, 'a reference is returned as it is';
  is $s->_mask_error_values('', [], undef), '', 'the empty text stays';

  is $s->_mask_error_values(
    "Syntax error during implicit conversion of CHAR value 'ab' to a DATE field.", [], undef),
    "Syntax error during implicit conversion of CHAR value '***' to a DATE field.",
    'a short value in a sentence of the engine';

  is $s->_mask_error_values(
    q{Attempt to insert NULL value into column 'id', table 't'; column does not allow nulls.},
    ['geheimwert'], 'INSERT INTO t (id) VALUES (?)'),
    q{Attempt to insert NULL value into column 'id', table 't'; column does not allow nulls.},
    'a text without a value is as it was';

  is $s->_mask_error_values('value geheimwert here', ['geheimwert'], undef),
    'value *** here', 'a bound value elsewhere in the text';

  ok eval { $s->_mask_error_values("x", "not a list", 3); 1 }, 'it does not throw on odd arguments';
};

{
  package T::Sth;
  our (@FUNC_RESULTS, $ERRSTR);
  sub new { bless {}, shift }
  sub func { shift @FUNC_RESULTS }
  sub fetch { undef }
  sub errstr { $ERRSTR }
  sub finish { 1 }
}
{
  package T::Cursor;
  sub new { bless { sth => $_[1] }, $_[0] }
  sub next { 1 }
  sub sth { $_[0]{sth} }
}
{
  package T::Source;
  sub new { bless {}, shift }
  sub name { 'doc' }
  sub _pri_cols_or_die { qw/k1 k2/ }
}
{
  package T::LobStorage;
  use base 'DBIO::Sybase::Storage::ASE';
  our ($CURSOR_STH, $FREETDS);
  sub select { T::Cursor->new($CURSOR_STH) }
  sub _get_dbh { bless {}, 'T::Dbh' }
  sub _using_freetds { $FREETDS }
  sub _blob_log_on_update { 1 }
}

# --- the TEXT/IMAGE writer -----------------------------------------------

subtest 'LOBWriter: no row found names the key columns, not their values' => sub {
  local $T::LobStorage::CURSOR_STH = undef;
  my $s = T::LobStorage->new;
  my $err = eval { $s->_insert_blobs(T::Source->new, { body => 'geheiminhalt' },
    { k1 => 'geheimschluessel1', k2 => 'geheimschluessel2' }); 1 } ? '' : "$@";
  ok length $err, 'it throws';
  unlike $err, qr/geheimschluessel|geheiminhalt/, 'no value';
  like $err, qr/table 'doc'/, 'the table stays';
  like $err, qr/k1, k2/, 'the key columns stay';
};

for my $freetds (0, 1) {
  subtest "LOBWriter: the error of the client library, FreeTDS=$freetds" => sub {
    local $T::LobStorage::CURSOR_STH = T::Sth->new;
    local $T::LobStorage::FREETDS = $freetds;
    local @T::Sth::FUNC_RESULTS = (1, 0);   # CS_GET works, ct_prepare_send fails
    local $T::Sth::ERRSTR = "ct_prepare_send failed for 'geheimschluessel1' with geheiminhalt";
    my $s = T::LobStorage->new;
    my $err = eval { $s->_insert_blobs(T::Source->new, { body => 'geheiminhalt' },
      { k1 => 'geheimschluessel1', k2 => 'geheimschluessel2' }); 1 } ? '' : "$@";
    ok length $err, 'it throws';
    unlike $err, qr/geheimschluessel1|geheiminhalt/, 'neither the key nor the content';
    like $err, qr/ct_prepare_send failed/, 'the error stays';
    like $err, qr/FreeTDS/, 'the hint for FreeTDS stays' if $freetds;
  };
}

# --- the bulk path --------------------------------------------------------

{
  package T::BulkInner;
  sub new { bless { name => $_[1] }, $_[0] }
  sub txn_scope_guard { bless {}, 'T::Guard' }
  sub sql_maker { $_[0] }
  sub _quote { $_[1] }
  sub _get_dbh { bless {}, 'T::BulkDbh' }
  sub _query_end { }
  sub disconnect { $T::BulkStorage::DISCONNECTED++ }
  # the settings the storage proxies to its bulk storage
  sub AUTOLOAD { return }
  sub DESTROY { }
  package T::Guard; sub commit { 1 }
  package T::BulkDbh; sub prepare { bless {}, 'T::BulkSth' } sub isa { 0 }
  package T::BulkSth; sub finish { 1 }
}
{
  package T::BulkSource;
  sub new { bless {}, shift }
  sub name { 'bulk' }
  sub columns { qw/id v/ }
  sub has_column { 1 }
  sub column_info { { data_type => 'varchar' } }
  sub columns_info { { id => { is_auto_increment => 1 }, v => { data_type => 'varchar' } } }
}
{
  package T::BulkStorage;
  use base 'DBIO::Sybase::Storage::ASE';
  our ($DISCONNECTED, $LIBRARY_SAYS, $DIES_WITH, $CALLBACK);
  sub _get_dbh { bless { syb_has_blk => 1 }, 'T::BulkDbh' }
  sub _using_freetds { 0 }
  sub _bulk_storage { $_[0]{bulk} //= T::BulkInner->new }
  sub _dbi_connect_info { [ 'dbi:Sybase:x' ] }
  sub _resolve_bindattrs { [] }
  sub _dbh_execute_for_fetch {
    # the client library calls the callback it was given, then the statement fails
    $CALLBACK->(@$LIBRARY_SAYS);
    die $DIES_WITH;
  }
}

subtest 'bulk path: the callback and the exception hold no value of the rows' => sub {
  local $T::BulkStorage::DISCONNECTED = 0;
  local $T::BulkStorage::LIBRARY_SAYS = [
    1, 2, 3, 99, "cs_convert: to_numeric() failed for 'geheimzahl'", "os says geheimzahl", "blk says geheimzahl",
  ];
  local $T::BulkStorage::DIES_WITH = "bulk insert failed: to_numeric() failed for 'geheimzahl' (row geheimtext)";

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  # DBD::Sybase keeps the callback in one slot; the test takes the one it is given
  no warnings 'redefine';
  local *DBD::Sybase::set_cslib_cb = sub { $T::BulkStorage::CALLBACK = $_[0] if $_[0]; return };
  my $s = T::BulkStorage->new;
  my $err = eval { $s->_insert_bulk(T::BulkSource->new, [qw/id v/],
    [ [ 1, 'geheimzahl' ], [ 2, 'geheimtext' ] ]); 1 } ? '' : "$@";

  ok length $err, 'the bulk insert fails';
  unlike $err, qr/geheimzahl|geheimtext/, 'no value in the exception';
  like $err, qr/to_numeric\(\) failed for '\*\*\*'/, 'the failure stays named';
  is $T::BulkStorage::DISCONNECTED, 1, 'the bulk connection is dropped as before';

  my $w = join '', @warnings;
  ok length $w, 'the callback warns';
  unlike $w, qr/geheimzahl/, 'no value in the warning';
  like $w, qr/Layer: 1, Origin: 2, Severity: 3, Error: 99/, 'the numbers stay';
  like $w, qr/to_numeric\(\) failed for '\*\*\*'/, 'the text of the library stays';
};

# --- the warning of the client library ------------------------------------

{
  package T::WarnSth;
  our $SAY;
  sub new { bless {}, shift }
  sub execute { warn $_ for @$SAY; 1 }
  package T::WarnDbh;
  sub new { bless {}, shift }
}
{
  package T::WarnStorage;
  use base 'DBIO::Sybase::Storage::ASE';
}

subtest '_execute_sth: only the conversion warning is masked' => sub {
  my $s = T::WarnStorage->new;
  my $dbh = {};
  my $sth = bless { ParamValues => { 1 => 'geheimmoney', 2 => 5 } }, 'T::WarnSth2';
  { package T::WarnSth2; our @ISA = ('T::WarnSth'); }

  local $T::WarnSth::SAY = [
    "cs_convert failed (to_money(geheimmoney)) at /lib/x.pm line 3.\n",
    "something else geheimmoney at /lib/x.pm line 4.\n",
    "cs_convert failed (to_money(a)b)c)) at /lib/x.pm line 5.\n",
  ];

  my @seen;
  {
    local $SIG{__WARN__} = sub { push @seen, @_ };
    $s->_execute_sth($dbh, $sth);
  }
  is scalar @seen, 3, 'every warning is handed on';
  is $seen[0], "cs_convert failed (to_money(***)) at /lib/x.pm line 3.\n", 'the value of the conversion goes, the place stays';
  like $seen[1], qr/geheimmoney/, 'a warning that is no conversion is not touched';
  is $seen[2], "cs_convert failed (to_money(***)) at /lib/x.pm line 5.\n", 'a value with parentheses';

  is $SIG{__WARN__}, undef, 'the caller handler is back after the statement' if !defined $SIG{__WARN__};
};

done_testing;
