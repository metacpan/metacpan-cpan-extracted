# ABSTRACT: No stack trace DBIO_TRACE=1 switches on quotes a password
use strict;
use warnings;

# DBIO::Schema reads it when it is loaded: this is the default of stacktrace()
BEGIN { $ENV{DBIO_TRACE} = 1 }

use Test::More;

use DBIO::Schema;

# OFFLINE (karr k304). The other way to a stack trace: nobody calls
# stacktrace(1), DBIO_TRACE=1 is in the environment -- as it is when somebody
# is looking for an error, with the output going to a terminal, a log or a bug
# report. The card's case then reads the same as with stacktrace(1): the
# storage_type cannot be loaded, the exception comes with the stack, and the
# stack has the frames a schema is connected through, with their arguments.
#
# What this file claims: that trace carries no password either -- not the
# password argument, not one inside the DSN -- while the frames, the DSN and
# the user name stand. Everything else about the masking is claimed by
# t/schema/stacktrace_no_password.t; this file is only about the switch, which
# has to be set before DBIO::Schema is loaded and so cannot share a file with
# cases that need it off.
#
# THE SUBSTITUTIONS: none. The storage class is a name without a file, so no
# storage is built and no statement is traced. The secrets are marker strings.

my $SECRET = qr/k304-secret/;
my $AS_ARG = 'k304-secret-as-argument';
my $IN_DSN = 'k304-secret-in-the-dsn';
my $USER   = 'k304-user';
my $FILE   = quotemeta __FILE__;

{
  package T::K304::Unloadable;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K304::NoSuchStorage');
}

ok( T::K304::Unloadable->stacktrace, 'DBIO_TRACE=1: stacktrace() is on without anybody calling it' );

{
  my $dsn = 'dbi:K304:dbname=app;host=db.example';
  my $trace = eval { T::K304::Unloadable->connect($dsn, $USER, $AS_ARG); 1 } ? undef : "$@";

  like $trace, qr/Unable to load storage class T::K304::NoSuchStorage/,
    'DBIO_TRACE=1: dies of the storage class that cannot be loaded';
  unlike $trace, $SECRET, 'DBIO_TRACE=1: ... without the password';
  like $trace, qr/^\tDBIO::Schema::connection\(T::K304::Unloadable=HASH\(0x[0-9a-f]+\), "\Q$dsn\E", "\Q$USER\E", "\*\*\*"\) called at \S*Schema\.pm line \d+$/m,
    'DBIO_TRACE=1: connection() stands, the password masked';
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "\Q$dsn\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'DBIO_TRACE=1: connect() stands, the password masked, with the file and line of the caller';
}

{
  my $dsn = "dbi:K304:dbname=app;password=$IN_DSN;host=db.example";
  my $trace = eval { T::K304::Unloadable->connect($dsn, $USER); 1 } ? undef : "$@";

  unlike $trace, $SECRET, 'DBIO_TRACE=1, a password inside the DSN: not in the trace';
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "dbi:K304:dbname=app;password=\*\*\*;host=db\.example", "\Q$USER\E"\) called at /m,
    'DBIO_TRACE=1, a password inside the DSN: the key and the rest of the DSN stand';
}

done_testing;
