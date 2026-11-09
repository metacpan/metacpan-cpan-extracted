use strict;
use warnings;
use Test::More;
use File::Path qw/mkpath/;
use File::Temp qw/tempdir/;

use DBIO::Introspect::DBI;
use DBIO::Storage::DBI;

# dbiogen used to hardcode DBIO::Introspect::DBI, so a user with
# DBIO::MySQL installed never got information_schema accuracy or the driver's
# source_info. class_for_dbh routes through the one existing registry --
# DBIO::Storage::DBI's DBD-name -> storage-class map -- and every way that can
# go wrong has to land on the generic introspector, never on a die.

sub dbh_for { bless { Driver => { Name => $_[0] } }, 'Test::Fake::Dbh' }
sub resolve { DBIO::Introspect::DBI->class_for_dbh(dbh_for($_[0])) }

# --- a registered driver whose Introspect class is present and in contract ---

{
  package DBIO::TestDb::Introspect;
  use base 'DBIO::Introspect::Base';
  sub _build_model { {} }
  $INC{'DBIO/TestDb/Introspect.pm'} = __FILE__;
}

DBIO::Storage::DBI->register_driver(TestDb => 'DBIO::TestDb::Storage');

is resolve('TestDb'), 'DBIO::TestDb::Introspect',
  'the driver namespace behind the registered storage class supplies the introspector';

# The storage class is only a name here -- resolution must not need the driver's
# storage stack (and its DBD) to be loadable just to generate Result classes.
ok !$INC{'DBIO/TestDb/Storage.pm'},
  'resolving the introspector did not load the storage class';

# A driver registered under a Storage subclass (DBD::MariaDB is registered as
# DBIO::MySQL::Storage::MariaDB) still belongs to the parent driver namespace.
DBIO::Storage::DBI->register_driver(TestDbVariant => 'DBIO::TestDb::Storage::Variant');

is resolve('TestDbVariant'), 'DBIO::TestDb::Introspect',
  'a Storage:: subclass resolves to the same driver namespace';

# --- every failure mode falls back, none of them throws ---

is resolve('NoSuchDriverAnywhere'), 'DBIO::Introspect::DBI',
  'an unregistered DBD falls back to the generic introspector';

# Registered, but the driver distribution is not installed -- the everyday case
# for a user with only DBI and core DBIO.
DBIO::Storage::DBI->register_driver(TestAbsent => 'DBIO::TestAbsentDb::Storage');

is resolve('TestAbsent'), 'DBIO::Introspect::DBI',
  'a registered driver that is not installed falls back to the generic introspector';

{
  # Loadable, but not an introspector: generating from it would fail on the
  # first contract method, so it must not be selected.
  package DBIO::TestBogusDb::Introspect;
  sub new { bless {}, shift }
  $INC{'DBIO/TestBogusDb/Introspect.pm'} = __FILE__;
}

DBIO::Storage::DBI->register_driver(TestBogus => 'DBIO::TestBogusDb::Storage');

is resolve('TestBogus'), 'DBIO::Introspect::DBI',
  'a class that is not a DBIO::Introspect::Base is refused, not handed to Generate';

{
  # Installed but not loadable is a broken installation, not an absent driver:
  # falling back is still right (dbiogen has to stay usable), but doing it
  # quietly would hand the user less accurate Result classes and no reason why.
  my $libdir = tempdir(CLEANUP => 1);
  mkpath("$libdir/DBIO/TestBrokenDb");
  open my $fh, '>', "$libdir/DBIO/TestBrokenDb/Introspect.pm" or die $!;
  print $fh "package DBIO::TestBrokenDb::Introspect;\ndie \"kaboom\";\n1;\n";
  close $fh;
  local @INC = ($libdir, @INC);

  DBIO::Storage::DBI->register_driver(TestBroken => 'DBIO::TestBrokenDb::Storage');

  my @warnings;
  my $resolved = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    resolve('TestBroken');
  };

  is $resolved, 'DBIO::Introspect::DBI',
    'a driver whose introspector does not compile still yields a usable class';
  like "@warnings", qr/DBIO::TestBrokenDb::Introspect/,
    'the broken class is named in the warning';
  like "@warnings", qr/kaboom/,
    'the actual compile error is passed through, not swallowed';
  like "@warnings", qr/less accurate/,
    'the warning says what the fallback costs';
}

# ODBC is registered as DBIO::Storage::DBI::ODBC -- core itself, not a driver
# namespace. It must not be mangled into a DBIO::Introspect lookup.
is resolve('ODBC'), 'DBIO::Introspect::DBI',
  'a core storage class does not pretend to have a driver introspector';

# A handle that cannot even name its driver (a mock, a disconnected handle)
# still has to yield something usable.
{
  my $blind = bless {}, 'Test::Fake::Dbh';
  my $class = DBIO::Introspect::DBI->class_for_dbh($blind);
  is $class, 'DBIO::Introspect::DBI',
    'a handle without a Driver name falls back to the generic introspector';
}

# --- whatever comes back is ready to use ---

for my $driver (qw/TestDb NoSuchDriverAnywhere ODBC/) {
  my $class = resolve($driver);
  my $intro = eval { $class->new(dbh => 'fake-dbh') };
  ok $intro, "$driver: resolved class accepts new(dbh => ...)" or diag $@;
  is eval { $intro->dbh }, 'fake-dbh', "$driver: the handle is carried through";
  ok $class->isa('DBIO::Introspect::Base'),
    "$driver: resolved class implements the introspect contract";
}

done_testing;
