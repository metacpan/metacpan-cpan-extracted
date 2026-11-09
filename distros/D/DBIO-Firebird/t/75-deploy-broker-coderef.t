use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBI;
use DBIO::AccessBroker;
use DBIO::Firebird::Deploy;
use DBIO::Firebird::Storage;

# OFFLINE (karr k42).
#
# WHY: Deploy builds the temp database from the live connection's DSN: it reads
# where the live file is (server, directory) and connects to a second database
# beside it. A broker whose answer opens the connection itself -- a coderef as
# the DSN of the DBI form, or a dbh_maker in the hash form -- has no DSN to
# read. That stays refused, as it is without a broker, and loudly: an exception
# that says so, from every site that reads the live connection, and nothing
# that could carry a secret -- the answer's user and password are not in it.
#
# What this file claims, for both shapes of answer and both sites
# (_live_db_location, _temp_connect_info):
#   1. it dies with "does not support coderef DSN for temp database
#      connections";
#   2. the message quotes no DSN, user or password (core drops user and
#      password beside a dbh_maker, so the answer carries none; the check is
#      that nothing is invented or taken from elsewhere);
#   3. no connection was opened on the way.
#
# THE SUBSTITUTION: DBI->connect is a recorder; the coderefs of the answers
# count their calls. No database is involved.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
  sub get_info { 0 }
  sub disconnect { 1 }
}

my @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

{
  package T::Schema; sub new { bless { st => $_[1] }, $_[0] } sub storage { $_[0]{st} }
}

my ($USER, $SECRET) = ('k42-user', 'k42-secret');
my $made = 0;
my $maker = sub { $made++; T::Handle->new };

for my $case (
  [ 'DBI form, a coderef as the DSN' => sub { [ $maker, { AutoCommit => 1 } ] } ],
  [ 'hash form, a dbh_maker'          => sub { { dbh_maker => $maker } } ],
) {
  my ($label, $answer) = @$case;

  for my $site (
    [ '_live_db_location' => sub { $_[0]->_live_db_location } ],
    [ '_temp_connect_info' => sub { $_[0]->_temp_connect_info('host:/tmp/t.fdb') } ],
  ) {
    my ($site_name, $call) = @$site;

    my $storage = DBIO::Firebird::Storage->new(undef);
    $storage->connect_info([ T::Broker->new($answer->()) ]);
    my $deploy = DBIO::Firebird::Deploy->new(schema => T::Schema->new($storage));

    @CONNECTS = ();
    $made = 0;
    throws_ok { $call->($deploy) } qr/does not support coderef DSN for temp database connections/,
      "$label, $site_name: refused, saying why";
    unlike "$@", qr/\Q$USER\E|\Q$SECRET\E/, '... quoting neither the user nor the password';
    is scalar(@CONNECTS) + $made, 0, '... and no connection was opened';
  }
}

done_testing;
