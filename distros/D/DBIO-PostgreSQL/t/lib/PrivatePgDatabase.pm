package PrivatePgDatabase;

# A throwaway database of its own for one live test file (karr k81).
#
# A test that diffs or introspects the WHOLE database -- Deploy->diff and
# ->apply, an unfiltered Introspect compared against a synthesized target --
# also sees whatever else lives in the shared DBIO_TEST_PG_DSN database: other
# files' leftovers and, above all, extensions. pgvector is created there by
# t/48 and t/54 and stays. Deploy->diff rightly drops what the schema does not
# declare, so in the shared database such a test's result depended on which
# files had run before it (t/09 died or passed depending on whether vector was
# installed, t/16 found a "change" in an unchanged schema). Here the test owns
# everything it compares.
#
# The database is created from the default template -- the same one the
# Deploy temp database uses, so both sides of a diff start out alike -- and
# dropped at END. This module's END block is compiled when the test file
# loads it, before the file's own END blocks, so it runs after them: a file's
# own cleanup still finds its database. WITH (FORCE) (PostgreSQL 13+)
# terminates the connections the test still holds at that point.
#
# The connection that creates it and the DSN that names it come from
# LiveServer (karr k113): a server that is not there ends the file as a
# failed test with a plan, the reason without a password, and the name goes
# into the DSN as DBD::Pg and libpq read one, not by a substitution.

use strict;
use warnings;

use LiveServer;

my @created;

# ( $dsn, $user, $pass ) of a new database dbio_<tag>_<pid> on the test server.
sub create {
  my ($class, $tag) = @_;
  my $name    = "dbio_${tag}_$$";
  my @login   = LiveServer->login;
  my @private = LiveServer->login_for_database($name);

  my $dbh    = LiveServer->control_dbh(attrs => { PrintWarn => 0 });
  my $quoted = $dbh->quote_identifier($name);
  $dbh->do("DROP DATABASE IF EXISTS $quoted WITH (FORCE)");
  $dbh->do("CREATE DATABASE $quoted");
  $dbh->disconnect;
  push @created, [ \@login, $name ];

  return @private;
}

END {
  for my $db (@created) {
    my ($login, $name) = @$db;
    my $dbh = eval { LiveServer->dbh_or_die(login => $login, attrs => { RaiseError => 0 }) }
      or next;
    $dbh->do('DROP DATABASE IF EXISTS ' . $dbh->quote_identifier($name) . ' WITH (FORCE)');
    $dbh->disconnect;
  }
}

1;
