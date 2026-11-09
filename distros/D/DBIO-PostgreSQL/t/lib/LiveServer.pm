package LiveServer;

# The one way a live test of this distribution opens a DBI connection of its
# own -- beside the schema it tests -- and reads the test DSN (karr k113).
# Same name and the same four methods (login, conninfo, control_dbh,
# require_server) as t/lib/LiveServer.pm in dbio-postgresql-ev (there karr
# k77). That one asks its transport how a DSN reads; the future_io transport
# here hands the DSN to DBI as it is, so the reading is in this file.
#
# Both used to be written out in each file, and both went wrong there:
#
#   - DBI->connect($dsn, $user, $pass, { RaiseError => 1 }) stood uncaught.
#     With no server behind the DSN the file died in DBI's words, which quote
#     the DSN -- and with it a password the DSN carries (karr k111: no message
#     quotes a password) -- and without a plan. dbh_or_die below throws those
#     words masked; control_dbh and require_server end the file as a failed
#     test with a plan.
#
#   - The DSN was taken apart, and the name of a private database put into
#     it, with split /;/ and s/(dbname|database|db)=[^;]+/.../. That is not
#     how DBD::Pg and libpq read it: a quoted value with a ';' in it was cut
#     in two, and a dbname= inside another value was taken for the parameter.
#     read_dsn below reads a DSN as the two do, and dsn_with_dbname writes it
#     back through DBIO::PostgreSQL::Util::quote_dsn_value, the rule this
#     distribution writes a DSN by.
#
# A live file whose server is not there FAILS -- it does not skip. It was asked
# to run against a server (DBIO_TEST_PG_DSN is set), and a suite that reports
# green because every live file stepped aside has measured nothing. So every
# file that reads the test login calls LiveServer->require_server behind its
# own skips (no DSN set, an optional module missing): from there on the server
# is known to be there, whatever the file connects with afterwards -- a schema,
# whose connect error core masks itself, or a handle from here.
# t/109-live-files-use-live-server.t holds both: no DBI->connect outside this
# file, and the call in every such file.
#
# t/108-live-server.t is the offline test of this file, t/108-live-server-live.t
# has a real server read the DSNs written here.

use strict;
use warnings;

use DBI ();
use File::Basename ();
use Test::More ();
use DBIO::Util ();
use DBIO::PostgreSQL::Util ();

# The DSN, user and password of the test database, as the environment has them.
sub login { return @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) } }

# A DBI connection, or the reason there is none, thrown: DBI's words with the
# password as *** (DBIO::Util::mask_connect_secrets), ending in a newline.
# For where a failed connect is the caller's to deal with -- the cleanup in an
# END block, a subtest; a file's first connection is control_dbh.
#
#   login => [ $dsn, $user, $pass ]   another login than the environment's:
#                                     what PrivatePgDatabase->create returns
#   attrs => \%attrs                  DBI attributes; RaiseError, no
#                                     PrintError and AutoCommit where not given
#
# The connect itself always raises and never prints, whatever the attributes
# say -- with RaiseError off DBI would print the DSN instead of throwing it.
# The handle has the RaiseError and PrintError asked for.
sub dbh_or_die {
  my ($class, %opt) = @_;
  my ($dsn, $user, $pass) = $opt{login} ? @{ $opt{login} } : $class->login;
  my %attrs = (RaiseError => 1, PrintError => 0, AutoCommit => 1, %{ $opt{attrs} // {} });

  my $dbh = eval { DBI->connect($dsn, $user, $pass, { %attrs, RaiseError => 1, PrintError => 0 }) };
  if (!$dbh) {
    # a HandleError of the caller may have taken the error: DBI does not die then
    my $why = length $@ ? "$@" : 'DBI connect failed: ' . ($DBI::errstr // 'DBI does not say why');
    # where DBI was called from is this line, which says nothing about the test
    $why =~ s/ at \Q${\ __FILE__ }\E line \d+\.?\s*\z//;
    die DBIO::Util::mask_connect_secrets($why, [ $dsn, $user, $pass, \%attrs ]) . "\n";
  }

  $dbh->{$_} = $attrs{$_} for qw( RaiseError PrintError );
  return $dbh;
}

# A DBI connection of the test's own: the handle an Introspect reads through,
# the session that prepares or inspects a database, the sender of a NOTIFY.
# Takes what dbh_or_die takes.
#
# A server that does not take the connection ends the file: one failed test,
# the reason as a diagnostic with no password in it, a plan. Inside a subtest,
# which cannot end a file, the reason is thrown instead and the file dies of
# it -- so call this, or require_server, at the top level first.
sub control_dbh {
  my ($class, %opt) = @_;
  my $dbh = eval { $class->dbh_or_die(%opt) };
  return $dbh if $dbh;
  $class->_end('the server DBIO_TEST_PG_DSN names takes a connection', $@);
}

# The gate of a live file: asks the server for a connection and closes it, so
# that a server that is not there ends the file here, with a plan, and not at
# its first statement.
sub require_server {
  my ($class) = @_;
  $class->control_dbh->disconnect;
  return;
}

# The libpq parameters the test login makes, as a list of pairs for a hash:
# those of the DSN, then the user and the password given beside it -- which is
# the order libpq gets them in, and the later one counts.
sub conninfo {
  my ($class) = @_;
  my ($dsn, $user, $pass) = $class->login;
  my (undef, $pairs) = eval { $class->read_dsn($dsn) }
    or $class->_end('DBIO_TEST_PG_DSN is a dbi:Pg: DSN this helper reads', $@);

  # DBI and DBD::Pg take these for a user and a password not given
  $user //= $ENV{DBI_USER};
  $pass //= $ENV{DBI_PASS};
  return (
    (map { @$_ } @$pairs),
    (length($user // '') ? (user     => $user) : ()),
    (length($pass // '') ? (password => $pass) : ()),
  );
}

# The test login for another database of the same server: ( $dsn, $user,
# $pass ), the DSN naming $name and otherwise the parameters it had.
sub login_for_database {
  my ($class, $name) = @_;
  my ($dsn, $user, $pass) = $class->login;
  my $other = eval { $class->dsn_with_dbname($dsn, $name) }
    // $class->_end('DBIO_TEST_PG_DSN is a dbi:Pg: DSN this helper reads', $@);
  return ($other, $user, $pass);
}

# $dsn with the database $name in place of the one it names, or added where it
# names none. Every other parameter keeps its value; each value is written
# anew, by DBIO::PostgreSQL::Util::quote_dsn_value, and the database under the
# one keyword dbname -- which is also what core's Deploy looks for when it
# puts the name of its temporary database into the DSN of a schema. Throws
# what read_dsn throws.
sub dsn_with_dbname {
  my ($class, $dsn, $name) = @_;
  die "LiveServer: a database to name in a DSN needs a name\n"
    unless defined $name && !ref $name && length $name;

  my ($head, $pairs) = $class->read_dsn($dsn);

  my (@out, $named);
  for my $pair (@$pairs) {
    if ($pair->[0] ne 'dbname') { push @out, $pair }
    elsif (!$named++)           { push @out, [ dbname => $name ] }
  }
  push @out, [ dbname => $name ] unless $named;

  return $head . join ';',
    map { "$_->[0]=" . DBIO::PostgreSQL::Util::quote_dsn_value($_->[1]) } @out;
}

# A dbi:Pg: DSN as its two readers read it: ( $head, \@pairs ) -- 'dbi:Pg:'
# with the DBI attributes it may carry, and [ keyword, value ] for every
# parameter in the order given. A parameter given twice is there twice; the
# later one is the one libpq connects with.
#
# The readers, in their order (DBD::Pg 3.20.2, DBD::Pg::dr::connect and
# dbd_db_login6; libpq, conninfo_parse):
#   - DBD::Pg makes the first db= or database= a dbname=, and the first
#     dbname="..." a dbname='...' -- as text, wherever in the DSN it stands;
#   - DBD::Pg makes every ';' outside single quotes a blank; a backslash takes
#     the character behind it along;
#   - libpq reads keyword = value, blanks around the '=' allowed: a value in
#     single quotes to the closing one, a bare value to the next blank, a
#     backslash in either taking the character behind it for itself.
#
# Throws for what these do not read as parameters -- no dbi:Pg: DSN, a
# connection URI behind dbi:Pg:, a parameter without '=', a quote left open.
# The message says which, and repeats nothing of the DSN: a password may be
# anywhere in a DSN that is not read.
sub read_dsn {
  my ($class, $dsn) = @_;
  my ($head, $body) = defined $dsn && !ref $dsn
    ? $dsn =~ /\A((?i:dbi):Pg(?:\([^\n]*?\))?:)(.*)\z/s : ();
  die "LiveServer: not a dbi:Pg: DSN\n" unless defined $head;

  # DBD::Pg::dr::connect
  $body =~ s/\b(?:db|database)\s*=/dbname=/;
  $body =~ s/dbname\s*=\s*"(.+?)"/dbname='$1'/;

  # dbd_db_login6
  my ($conn, $inquote) = ('', 0);
  while ($body =~ /\G(\\.|.)/gs) {
    my $piece = $1;
    if    ($piece eq ';' && !$inquote) { $piece = ' ' }
    elsif ($piece eq q{'})             { $inquote = !$inquote }
    $conn .= $piece;
  }

  die "LiveServer: the DSN is a connection URI behind dbi:Pg:, which is not read here\n"
    if $conn =~ m{\Apostgres(?:ql)?://};

  # conninfo_parse
  my @pairs;
  while ($conn =~ /\S/) {
    $conn =~ s/\A\s*([^=\s]*)\s*//;
    my $key = $1;
    $conn =~ s/\A=\s*//
      or die qq{LiveServer: the DSN has a parameter without "=" behind its name\n};
    # a second db= is none DBD::Pg rewrites: libpq refuses it
    die "LiveServer: the DSN has a parameter whose name is no libpq keyword\n"
      unless $key =~ /\A[A-Za-z_]\w*\z/ && $key !~ /\A(?:db|database)\z/;

    my $value = '';
    if ($conn =~ s/\A'//) {
      until ($conn =~ s/\A'//) {
        $conn =~ s/\A(?:\\(.)|([^'\\]+))//s
          or die "LiveServer: the DSN has a quote that is not closed\n";
        $value .= $1 // $2;
      }
    }
    else {
      $value .= $1 // $2 // '' while $conn =~ s/\A(?:\\(.)|([^\s\\]+)|\\\z)//s;
    }
    push @pairs, [ $key, $value ];
  }

  return ($head, \@pairs);
}

# One failed test, why, a plan, the end. $why comes from this file: DBI's
# words already masked by dbh_or_die, or words of read_dsn, which repeat
# nothing of a DSN.
sub _end {
  my ($class, $claim, $why) = @_;

  # a subtest cannot end the file: its caller gets the reason
  die $why if Test::More->builder->parent;

  # the failure is reported at the test file's line, not at one in t/lib
  my $lib    = File::Basename::dirname(__FILE__);
  my $inside = 0;
  $inside++ while File::Basename::dirname((caller $inside)[1] // '') eq $lib;
  local $Test::Builder::Level = $Test::Builder::Level + $inside + 1;

  Test::More::fail($claim);
  Test::More::diag($why);
  Test::More::done_testing();
  exit;
}

1;
