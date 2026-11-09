use strict;
use warnings;
use Test::More;

# Offline test for karr k149: _create_temp_db and _drop_temp_db do not
# commit the caller's transaction.
#
# Claim: CREATE/DROP DATABASE cannot run in a transaction block, and the
# deploy does not get out of that by committing a transaction that is not its
# own. A handle with AutoCommit off makes both methods die, naming the method
# and the open transaction, before any statement (COMMIT included) is sent;
# AutoCommit stays off. On an AutoCommit handle the one statement runs, with
# no COMMIT ahead of it.

use DBIO::PostgreSQL::Deploy;

{
  package T193::Dbh;
  sub new { bless { AutoCommit => $_[1], pg_server_version => 140000, log => [] }, $_[0] }
  sub selectrow_hashref { { encoding => 'UTF8', collate => 'C', ctype => 'C' } }
  sub do { my $s = shift; push @{ $s->{log} }, $_[0]; 1 }
}

my $deploy = DBIO::PostgreSQL::Deploy->new(schema => undef);

for my $case (
  [ _create_temp_db => sub { $deploy->_create_temp_db($_[0]) } ],
  [ _drop_temp_db   => sub { $deploy->_drop_temp_db($_[0], 'gone_db') } ],
) {
  my ($method, $call) = @$case;

  my $open = T193::Dbh->new(0);
  my $ok = eval { $call->($open); 1 };
  my $err = $@;
  ok !$ok, "$method: dies on a handle inside a transaction";
  like "$err", qr/\Q$method\E.*the handle is inside a transaction.*TempDatabase passes a handle with AutoCommit on \(_admin_dbh\)/s,
    "$method: message names the method, the transaction and the _admin_dbh of TempDatabase";
  is_deeply $open->{log}, [], "$method: no statement ran (no COMMIT, no DATABASE statement)";
  is $open->{AutoCommit}, 0, "$method: AutoCommit is still off, the transaction stands";

  my $auto = T193::Dbh->new(1);
  $call->($auto);
  is scalar @{ $auto->{log} }, 1, "$method: one statement on an AutoCommit handle";
  unlike $auto->{log}[0], qr/COMMIT/, "$method: no COMMIT";
  is $auto->{AutoCommit}, 1, "$method: AutoCommit still on";
}

{
  my $dbh = T193::Dbh->new(1);
  my $name = $deploy->_create_temp_db($dbh);
  like $dbh->{log}[0], qr/^CREATE DATABASE \Q$name\E TEMPLATE template0 /, 'CREATE DATABASE of the temp name';
  $deploy->_drop_temp_db($dbh, $name);
  like $dbh->{log}[1], qr/^DROP DATABASE IF EXISTS \Q$name\E$/, 'DROP DATABASE IF EXISTS';
}

done_testing;
