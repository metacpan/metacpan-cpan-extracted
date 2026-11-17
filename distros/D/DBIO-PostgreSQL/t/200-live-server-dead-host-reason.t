use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# OFFLINE test of LiveServer->dead_host_reason, the pattern a test uses for
# libpq's reason when it connects to a socket directory that does not exist.
#
# WHY: a libpq without Unix-domain sockets (the libpq of Strawberry Perl 5.20
# on Windows) takes "/nonexistent/..." for a host name, goes to TCP localhost
# and never names a socket path. A test that wanted the path in the text failed
# there although nothing was wrong: the password was masked and libpq's reason
# was in the text. t/105 and t/87 cannot be shown red on Linux, whose libpq
# does know sockets; so this file puts both libpqs' real texts through the
# helper, with libpq_has_unix_sockets forced to each answer.
#
# What this file claims:
#   1. where libpq has sockets, the reason is the socket path of the directory:
#      the Linux text matches, the Windows text does not;
#   2. where it has none, the reason is a failed connection: the Windows text
#      matches, and so does the Linux text (one wording either way);
#   3. a text that is no connection failure matches neither.

my $DIR = '/nonexistent/dbio-postgresql-k200';

# libpq 17 on Linux, from a real run.
my $LINUX = qq{DBI connect('dbname=a;host=$DIR','a',...) failed: connection to server on socket "$DIR/.s.PGSQL.5432" failed: No such file or directory\n}
          . qq{\tIs the server running locally and accepting connections on that socket? at -e line 1.\n};

# libpq of Strawberry Perl 5.20 on Windows, from the smoke log.
my $WINDOWS = qq{DBI connect('host=$DIR;dbname=appdb','app',...) failed: could not connect to server: Connection refused (0x0000274D/10061)\n}
            . qq{\tIs the server running on host "localhost" (::1) and accepting\n\tTCP/IP connections on port 5432?\n}
            . qq{could not connect to server: Connection refused (0x0000274D/10061)\n}
            . qq{\tIs the server running on host "localhost" (127.0.0.1) and accepting\n\tTCP/IP connections on port 5432?\n};

my $UNRELATED = "something else went wrong in the test\n";

{
  no warnings 'redefine';
  local *LiveServer::libpq_has_unix_sockets = sub { 1 };
  my $re = LiveServer->dead_host_reason($DIR);
  like   $LINUX,     $re, 'with sockets: the Linux text names the socket';
  unlike $WINDOWS,   $re, '... the TCP text of a libpq without sockets does not';
  unlike $UNRELATED, $re, '... an unrelated text does not';
  unlike "socket \"/other/dir/.s.PGSQL.5432\"", $re, '... another directory does not';
}

{
  no warnings 'redefine';
  local *LiveServer::libpq_has_unix_sockets = sub { 0 };
  my $re = LiveServer->dead_host_reason($DIR);
  like   $WINDOWS,   $re, 'without sockets: the Windows text is a failed connection';
  like   $LINUX,     $re, '... and so is the Linux text';
  unlike $UNRELATED, $re, '... an unrelated text is not';
}

done_testing;
