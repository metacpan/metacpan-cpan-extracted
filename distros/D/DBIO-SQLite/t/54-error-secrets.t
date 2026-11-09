use strict;
use warnings;
use Test::More;
use DBIO::SQLite::Storage;

# karr k83: no message this driver writes carries the password of the connect
# info. The driver has no site of its own that writes a DSN into a message;
# the connect-failure text is core's (mask_connect_secrets), and this pins
# that it stays masked on the SQLite path.

BEGIN { delete @ENV{qw(DBI_DSN DBI_DRIVER)} }

my $secret = 'S3kr3tPassw0rd';

{
  package SecretSchema;
  our @ISA = 'DBIO::Schema';
  require DBIO::Schema;
  __PACKAGE__->load_components('SQLite');
}

for my $case (
  [ 'password argument'  => [ 'dbi:SQLite:dbname=/nonexistent/dir/x.db', 'u', $secret, {} ] ],
  [ 'password in the DSN' => [ "dbi:SQLite:dbname=/nonexistent/dir/x.db;password=$secret", 'u', '', {} ] ],
  [ 'Password attribute' => [ 'dbi:SQLite:dbname=/nonexistent/dir/x.db', 'u', '', { Password => $secret } ] ],
) {
  my ($name, $ci) = @$case;
  my $schema = SecretSchema->connect(@$ci);
  eval { $schema->storage->dbh; 1 };
  my $err = "$@";
  ok length $err, "$name: connect to an unopenable file fails";
  unlike $err, qr/\Q$secret\E/, "$name: the message does not carry the password";
}

done_testing;
