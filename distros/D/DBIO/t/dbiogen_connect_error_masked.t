# ABSTRACT: bin/dbiogen never quotes the connect info's password when the connect fails
use strict;
use warnings;

use Test::More;
use File::Temp ();
use IPC::Open3 qw(open3);
use Config;

use DBIO::Util qw(file_path mkpath write_file);

# OFFLINE (karr k305). dbiogen takes its connect info from @ARGV and used to
# connect with DBI's default PrintError: DBI then wrote the failed connect
# to STDERR with the DSN as it was given, password part and all, and the
# driver's own text on top of it.
#
# What this file claims, with a DBD of this file that refuses every connection
# and says what it was asked with (DSN, user, password):
#   1. dbiogen exits non-zero and reports "Could not connect to database";
#   2. neither the password in the DSN nor the password argument stands
#      anywhere in what it printed, on either stream;
#   3. the report still names the data source, so it is of use: the DSN with
#      the password masked.

my $IN_DSN = 'k305-secret-in-the-dsn';
my $AS_ARG = 'k305-secret-as-argument';

my $lib = File::Temp->newdir;
mkpath(file_path($lib->dirname, 'DBD'));
write_file(file_path($lib->dirname, 'DBD', 'K305Refuse.pm'), <<'PM');
package DBD::K305Refuse;
use strict;
use warnings;
use DBI ();
our $drh;
sub driver { $drh ||= DBI::_new_drh("$_[0]::dr", { Name => 'K305Refuse', Version => '0.01' }) }

package DBD::K305Refuse::dr;
our $imp_data_size = 0;
sub connect {
  my ($drh, $dsn, $user, $auth) = @_;
  $drh->set_err(1, sprintf 'refused [%s] [%s] [%s]', map { $_ // '' } $dsn, $user, $auth);
  return;
}

package DBD::K305Refuse::db;
our $imp_data_size = 0;

package DBD::K305Refuse::st;
our $imp_data_size = 0;

1;
PM

# Runs bin/dbiogen with the connect info as separate arguments (no shell, so
# no quoting of the DSN), both streams into one pipe.
sub run_dbiogen {
  my @connect = @_;
  local $ENV{PERL5LIB} = join $Config{path_sep}, $lib->dirname, grep { defined } $ENV{PERL5LIB};
  my $pid = open3(my $in, my $fh, undef, $^X, '-Ilib', 'bin/dbiogen',
    '-o', 'quiet=1', 'My::Schema', @connect);
  close $in;
  my $text = do { local $/; <$fh> };
  waitpid $pid, 0;
  return ($text, $? >> 8);
}

# A refused connection: DBI->connect returns undef
{
  my $dsn = "dbi:K305Refuse:dbname=app;password=$IN_DSN;host=db.example";
  my ($out, $status) = run_dbiogen($dsn, 'k305user', $AS_ARG);

  isnt $status, 0, 'dbiogen exits non-zero when the connect fails';
  like $out, qr/Could not connect to database/, '... and says so';
  unlike $out, qr/k305-secret/, '... with no password of the connect info in it';
  like $out, qr/dbname=app;password=\*\*\*;host=db\.example/,
    '... naming the data source, password masked';
}

# A DSN without the "dbi:<driver>:" prefix: DBI->connect dies, quoting the DSN
{
  my $dsn = "dbname=app;password=$IN_DSN;host=db.example";
  my ($out, $status) = run_dbiogen($dsn, 'k305user', $AS_ARG);

  isnt $status, 0, 'a DSN without driver: dbiogen exits non-zero';
  like $out, qr/Could not connect to database/, '... and says so, in the same words';
  unlike $out, qr/k305-secret/, '... with no password, from the DSN or the argument, in it';
  like $out, qr/password=\*\*\*/, '... the DSN named, password masked';
}

done_testing;
