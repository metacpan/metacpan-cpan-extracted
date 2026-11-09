use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Schema;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

# Every message of this driver that can carry the connect info goes through
# DBIO::Util::mask_connect_secrets (karr k89): a password in the connect info
# is not in what the driver throws.
#
# The declared storage connects at its first use, in the access-path hook
# (DBIO::Sybase::Storage::_adapt_to_access_path), to ask the client library
# what it is. When that connect fails, DBI quotes the DSN it was given, and the
# error that reaches the caller does not carry the password. OFFLINE:
# DBI->connect is replaced by one that dies the way DBD::Sybase does.

my $secret = 'Zx9-SeKr3t-Pw';

my @CONNECTS;
no warnings 'redefine';
local *DBI::connect = sub {
  shift;
  push @CONNECTS, [ @_ ];
  die "DBI connect('$_[0]','$_[1]','$_[2]') failed: Server is unavailable\n";
};
use warnings 'redefine';

my $n = 0;
my @KEEP;

for my $case (
  [ 'declared base',      sub { $_[0]->load_components('Sybase') } ],
  [ 'pinned ASE class',   sub { $_[0]->storage_type('+DBIO::Sybase::Storage::ASE') } ],
) {
  my ($name, $declare) = @$case;

  my $class = 'T::K89::Schema' . ++$n;
  { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Schema') }
  $declare->($class);

  my $schema = $class->connect(
    "dbi:Sybase:server=nosuchserver;database=x;password=$secret",
    'someuser', $secret, { RaiseError => 1, PrintError => 0 },
  );
  push @KEEP, $schema;
  my $storage = $schema->storage;

  @CONNECTS = ();
  my $err = eval { $storage->ensure_connected; 1 } ? '' : "$@";

  ok scalar @CONNECTS, "$name: the first use connected, and the connect failed";
  like $err, qr/Server is unavailable/, "$name: the first use throws the failure";
  unlike $err, qr/\Q$secret\E/, "$name: the password is not in the message";
  ok !$storage->_driver_determined, "$name: the driver is left undetermined";
}

done_testing;
