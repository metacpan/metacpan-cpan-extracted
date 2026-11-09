# ABSTRACT: the query trace shows a connect statement's secrets as a fingerprint (karr k392)
use strict;
use warnings;

use Test::More;
use File::Temp ();

use DBIO::Test;
use DBIO::Storage::Statistics;

# A connect action (on_connect_do, PRAGMA key, ATTACH ... token=) goes through
# the query trace like any statement (query_start and query_end), and its text
# carries the secret. The
# trace shows ***[sha256:<8 hex>] for it, the same fingerprint for the same
# value, and the text of an ordinary statement stays as it is.

my $dir   = File::Temp::tempdir(CLEANUP => 1);
my $file  = "$dir/trace.out";

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;
{ package K392::Stats; our @ISA = ('DBIO::Storage::Statistics'); our @ended;
  sub query_end { my $s = shift; push @ended, $_[0]; $s->SUPER::query_end(@_) } }
my $stats = K392::Stats->new;
$storage->debugobj($stats);
$storage->debug(1);

# the trace file is the one DBIO_TRACE names
$ENV{DBIO_TRACE} = "1=$file";

# A connect action runs with its statement in flight (_do_query)
sub connect_statement {
  my ($sql) = @_;
  local $storage->{_statement_in_flight} = $sql;
  $storage->_query_start($sql, []);
  $storage->_query_end($sql, []);
}
my $secret = 'sekret-Passphrase-42';
connect_statement("PRAGMA key = '$secret'");
connect_statement("PRAGMA key = '$secret'");
connect_statement("PRAGMA key = 'other-secret'");
$storage->_query_start("SELECT 'plain' AS shown", []);

open my $fh, '<', $file or die $!;
my $trace = do { local $/; <$fh> };
close $fh;

unlike $trace, qr/\Q$secret\E|other-secret/, 'no secret value in the trace';
my @prints = $trace =~ /PRAGMA key = \*\*\*\[sha256:([0-9a-f]{8})\]/g;
is scalar @prints, 3, 'each connect statement shows a fingerprint';
is $prints[0], $prints[1], 'one value, one fingerprint';
isnt $prints[0], $prints[2], 'another value, another fingerprint';
like $trace, qr/SELECT 'plain' AS shown/, 'the text of the plain statement is as it is';
unlike $trace, qr/SELECT 'plain'[^\n]*sha256/, 'and carries no fingerprint';

is_deeply [ grep { /PRAGMA/ } @K392::Stats::ended ],
  [ map { "PRAGMA key = ***[sha256:$_]" } @prints ],
  'query_end is handed the same masked text';

# the trace file
SKIP: {
  skip 'file modes are not POSIX here', 1 if $^O eq 'MSWin32';
  is sprintf('%04o', (stat $file)[2] & 07777), '0600', 'the trace file is created 0600';
}

done_testing;
