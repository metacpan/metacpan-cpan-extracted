use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Schema;
use DBIO::MSSQL::Storage::ODBC;

# OFFLINE (karr k81, the reading half of k58). A DBD::ODBC without Unicode
# support returns a SQL_CHAR value as bytes, without the UTF-8 flag (an
# a-umlaut read back is two characters). The storage sets odbc_utf8_on on the
# handle once the connection says its client character set is UTF-8 -- the
# question the write path asks -- unless the connect info names odbc_utf8_on,
# and never for a DBD::ODBC with Unicode support. What a server returns:
# t/123-odbc-read-utf8-live.t. NOTHING HERE CONNECTS.

our $PROBE_ANSWER = 0xE4;     # what the connection says it holds for U+00E4
our $UNICODE      = 0;        # odbc_has_unicode of the fake handle
my  $PROBES;

{
  package T::K81U::STH;
  sub new { $PROBES++ if ($_[1] // '') =~ /UNICODE\(/; bless { Statement => $_[1] }, $_[0] }
  sub bind_param        { 1 }
  sub execute           { 1 }
  sub fetchrow_array    { $_[0]{Statement} =~ /UNICODE\(/ ? ($main::PROBE_ANSWER) : () }
  sub fetchrow_arrayref { return }
  sub fetch             { return }
  sub finish            { 1 }
  sub err               { undef }
  sub errstr            { undef }
  sub FETCH             { $_[0]{$_[1]} }
}
{
  package T::K81U::DBH;
  sub new {
    bless { Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
            Driver => { Name => 'ODBC' }, odbc_has_unicode => $main::UNICODE }, shift;
  }
  sub FETCH       { $_[0]{$_[1]} }
  sub ping        { 1 }
  sub disconnect  { 1 }
  sub get_info    { undef }
  sub do          { 1 }
  sub selectrow_array    { 1 }
  sub selectrow_arrayref { [ 1 ] }
  sub prepare        { T::K81U::STH->new($_[1]) }
  sub prepare_cached { T::K81U::STH->new($_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K81U::DBH->new };
use warnings 'redefine';

{
  package T::K81U::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}

my @KEEP;
sub handle {
  my (%attrs) = @_;
  my $schema = T::K81U::Schema->connect('dbi:ODBC:DSN=k81', 'u', 'p', {%attrs});
  push @KEEP, $schema;
  $schema->storage->ensure_connected;
  isa_ok $schema->storage, 'DBIO::MSSQL::Storage::ODBC';
  return $schema->storage->dbh;
}

{
  local $PROBE_ANSWER = 0xE4;
  my $dbh = handle();
  is $dbh->{odbc_utf8_on}, 1, 'client character set UTF-8: odbc_utf8_on is set on the handle';
}
{
  local $PROBE_ANSWER = 0xC3;       # the UTF-8 bytes read as Latin-1
  my $dbh = handle();
  ok !$dbh->{odbc_utf8_on}, 'client character set is not UTF-8: left alone (the write path refuses there)';
}
{
  local $UNICODE = 1;
  $PROBES = 0;
  my $dbh = handle();
  ok !$dbh->{odbc_utf8_on}, 'DBD::ODBC with Unicode support: not set, it decodes by itself';
  is $PROBES, 0, '... and the connection is not asked';
}
{
  local $PROBE_ANSWER = 0xE4;
  $PROBES = 0;
  my $dbh = handle(odbc_utf8_on => 0);
  ok !$dbh->{odbc_utf8_on}, 'an explicit odbc_utf8_on => 0 in the connect info stays';
  is $PROBES, 0, '... and the connection is not asked';
}
done_testing;
