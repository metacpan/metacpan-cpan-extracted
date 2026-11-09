package LiveServer;

# The one way a live test of this distribution reads the test DSN and opens a
# connection of its own beside the transport (karr k77).
#
# Both used to be written out in each file, and both went wrong there:
#
#   - The DSN was taken apart at ';' and '='. That is not how the transport
#     reads it (karr k58): a quoted value, a ';' inside one, blanks around
#     '=', db= for dbname=, DBI attributes in front of the DSN -- each one a
#     DSN DBI and DBD::Pg connect with and the hand split read as something
#     else, so the pool of such a file would have gone somewhere the owner's
#     dbh does not. conninfo below asks the transport's own reader.
#
#   - DBI->connect($dsn, ...) stood uncaught. With no server behind the DSN
#     the file died before any plan ("No plan found"), in DBI's words, which
#     quote the DSN -- and with it a password the DSN carries (karr k78: no
#     message quotes a password). A file without such a connection died the
#     same way a few lines later, at its first statement. control_dbh and
#     require_server below end the file as a failed test with a plan, the
#     reason masked.
#
# A live file whose server is not there FAILS -- it does not skip. It was asked
# to run against a server (DBIO_TEST_PG_DSN is set), and a suite that reports
# green because every live file stepped aside has measured nothing.
#
# Call these at the top level of a file, not inside a subtest: they end the
# file, and a subtest cannot.
#
# Not part of the installed DBIO::PostgreSQL::EV::TestHarness: that one is
# public interface, consumed by other distributions.

use strict;
use warnings;

use DBI ();
use Test::More ();
use DBIO::Util ();
use DBIO::PostgreSQL::EV::ConnectInfo ();

# The DSN, user and password of the test database, as the environment has them.
sub login { return @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) } }

# The libpq parameters the test login makes, as a list of pairs: the DBI form
# [ $dsn, $user, $pass ] read as the transport reads it for a pool from static
# connect info (DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo with
# env => 1; t/53-dbi-to-conninfo.t holds that reading against DBI and libpq).
# What a storage takes as connect_info([ { LiveServer->conninfo }, {} ]).
#
# DBI_USER and DBI_PASS stand for a user and a password the login leaves
# undefined, as DBI reads them for control_dbh and as dbio-postgresql's helper
# reads them: a pool connected from this and the control dbh beside it log in
# as the same user (karr k88, maintainer's decision 2026-10-16).
sub conninfo {
  my ($class) = @_;
  my ($dsn, $user, $pass) = $class->login;
  my $read = eval { DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo([ $dsn, $user, $pass ], env => 1) }
    or $class->_end('DBIO_TEST_PG_DSN is a dbi:Pg: DSN the transport reads', $@);
  return %{ $read->[0] };
}

# A DBI connection of the test's own to the test database: the observer that
# asks the server what a pool did, the session that holds a lock, the sender
# of a NOTIFY. RaiseError, no PrintError, AutoCommit.
#
#   application_name => $name   its backend's application_name (PGAPPNAME for
#                               this connection alone)
#   login            => [ $dsn, $user, $pass ]   another database than the
#                               test's own (a private one a file created)
#   attrs            => \%attrs DBI attributes set on the handle once it is
#                               connected (after those three, so they never
#                               shape how a failed connect is reported)
#
# A server that does not take the connection ends the file: one failed test,
# the reason as a diagnostic with no password in it, a plan.
sub control_dbh {
  my ($class, %opt) = @_;
  my ($dsn, $user, $pass) = $opt{login} ? @{ $opt{login} } : $class->login;
  local $ENV{PGAPPNAME} = $opt{application_name} if defined $opt{application_name};
  # The caller's attrs are set on the handle after the connect: given to the
  # connect, they could turn RaiseError off and PrintError on, and a refused
  # connect would then be printed by DBI (DSN and all) with nothing left in $@
  # for _end to report masked.
  my $dbh = eval {
    my $h = DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    my %attrs = %{ $opt{attrs} // {} };
    $h->{$_} = $attrs{$_} for keys %attrs;
    $h;
  };
  return $dbh if $dbh;
  $class->_end('the server DBIO_TEST_PG_DSN names takes a connection', $@);
}

# For a file that opens no connection of its own: asks the server for one and
# closes it, so that a server that is not there ends the file here -- as
# control_dbh does -- and not at its first statement, before any plan.
sub require_server {
  my ($class) = @_;
  $class->control_dbh->disconnect;
  return;
}

# One failed test, why, a plan, the end. $why goes out masked: DBI's own words
# about a failed connect quote the DSN.
sub _end {
  my ($class, $claim, $why) = @_;

  # where DBI was called from is a line in here, which says nothing about the test
  $why = "$why";
  $why =~ s/ at \Q${\ __FILE__ }\E line \d+\.?\s*\z//;
  $why = DBIO::Util::mask_connect_secrets($why, [ $class->login ]);

  # a subtest cannot end the file: its caller gets the reason
  die "$why\n" if Test::More->builder->parent;

  # the failure is reported at the test file's line, not at one in here
  my $inside = 0;
  $inside++ while (caller $inside)[0] eq __PACKAGE__;
  local $Test::Builder::Level = $Test::Builder::Level + $inside + 1;
  Test::More::fail($claim);
  Test::More::diag($why);
  Test::More::done_testing();
  exit;
}

1;
