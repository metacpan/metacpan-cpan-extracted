use strict;
use warnings;
use Test::More;

use DBIO::Storage::DBI;
use DBIO::Storage::DBI::ODBC;
use DBIO::Storage::DBI::IdentityInsert;
use DBIO::Storage::DBI::UniqueIdentifier;
use DBIO::Storage::DBI::AutoCast;

# Method sections sat inside unterminated POD blocks (=method with no =cut
# before the sub), so the subs were never compiled. The same pattern buried
# IdentityInsert/AutoCast::_prep_for_execute and the UniqueIdentifier
# helpers -- exactly the MSSQL code paths the live tests saw missing.
#
# The connector detection is retired (ADR 0067): the ODBC class finds no engine.
# What it keeps are the transport helpers the ODBC storages of drivers inherit.

ok(!DBIO::Storage::DBI->can('_determine_connector_driver'),
  'the connector detection is gone');
eval { DBIO::Storage::DBI->register_connector_driver(Some_Engine => 'Some::Storage') };
isa_ok $@, 'DBIO::Exception', 'register_connector_driver, retired, throws';
like "$@", qr/register_connector_driver is retired \(ADR 0067\)/, '... naming the decision';

my %own_methods = (
  'DBIO::Storage::DBI::ODBC' =>
    [qw/_using_freetds _using_freetds_version _disable_odbc_array_ops _connect_params_dsn/],
  'DBIO::Storage::DBI::IdentityInsert' => [qw/_prep_for_execute/],
  'DBIO::Storage::DBI::UniqueIdentifier' => [qw/_is_guid_type _prefetch_autovalues/],
  'DBIO::Storage::DBI::AutoCast' => [qw/_prep_for_execute connect_call_set_auto_cast/],
);

for my $class (sort keys %own_methods) {
  for my $method (@{ $own_methods{$class} }) {
    my $code = $class->can($method);
    ok $code, "$class can $method";
    if (my $inherited = DBIO::Storage::DBI->can($method)) {
      isnt $code, $inherited, "$method is ${class}'s own, not inherited";
    }
  }
}

# Sweep the whole tree: no sub definition may sit inside a POD block.
use File::Find ();
my @buried;
File::Find::find(sub {
  return unless /\.pm\z/;
  open my $fh, '<', $_ or return;
  my $in_pod = 0;
  while (my $line = <$fh>) {
    if ($line =~ /^=cut\b/) { $in_pod = 0; next }
    if ($line =~ /^=\w+/)   { $in_pod = 1; next }
    push @buried, "$File::Find::name:$.: $line"
      if $in_pod && $line =~ /^sub\s+\w+.*[{;]/;
  }
}, 'lib');

is_deeply \@buried, [], 'no sub definitions buried inside POD blocks'
  or diag join '', @buried;

done_testing;
