use strict;
use warnings;
use Test::More;
use File::Temp ();
use FindBin ();

alarm 120;

# OFFLINE, karr k88: LiveServer->control_dbh ends the file as ONE failed test
# with the reason masked -- whatever DBI attributes the caller passes.
#
# WHY: the caller's attrs used to be spread behind RaiseError/PrintError into
# the connect. attrs of { RaiseError => 0, PrintError => 1 } then made DBI
# print the failed connect itself, DSN and all, to STDERR (a password the DSN
# carries with it), and left $@ empty, so _end had no reason to report masked.
# The attrs now go on the handle after the connect; the three fixed ones
# decide how a refused connect is reported.
#
# The server is a port nothing listens on, so the failure is real and needs no
# database. Each case runs the helper in a child perl: _end exits the file.

my $SECRET = 'k88-s3cret-pw';
my $lib    = "$FindBin::Bin/lib";

sub run_helper {
  my ($attrs_code) = @_;
  my $out = File::Temp->new;
  my $err = File::Temp->new;
  my $code = <<"CODE";
use strict; use warnings;
use lib '$lib';
use LiveServer;
LiveServer->control_dbh(attrs => $attrs_code);
CODE
  local %ENV = (
    %ENV,
    DBIO_TEST_PG_DSN  => "dbi:Pg:dbname=nodb;host=127.0.0.1;port=1;password=$SECRET",
    DBIO_TEST_PG_USER => 'nouser',
    DBIO_TEST_PG_PASS => $SECRET,
  );
  open my $pid, '-|' or do {
    open STDOUT, '>', $out->filename or die $!;
    open STDERR, '>', $err->filename or die $!;
    exec $^X, '-e', $code or die $!;
  };
  1 while <$pid>;
  close $pid;
  local $/;
  open my $o, '<', $out->filename or die $!;
  open my $e, '<', $err->filename or die $!;
  return (scalar <$o>, scalar <$e>);
}

my %case = (
  'no attrs'                       => '{}',
  'RaiseError 0, PrintError 1'     => '{ RaiseError => 0, PrintError => 1 }',
  'AutoInactiveDestroy'            => '{ AutoInactiveDestroy => 1 }',
);

for my $name (sort keys %case) {
  my ($out, $err) = run_helper($case{$name});
  $out //= '';
  $err //= '';
  unlike "$out$err", qr/\Q$SECRET\E/, "$name: no password reaches any output";
  is_deeply [ grep { length && !/^#/ } split /\n/, $err ], [],
    "$name: DBI printed nothing of its own (every STDERR line is a diagnostic)";
  like $out, qr/^not ok 1 - the server DBIO_TEST_PG_DSN names takes a connection/m,
    "$name: the file ends as one failed test";
  like "$out$err", qr/Connection refused|connection to server|could not connect/i,
    "$name: the reason is reported, not an empty diagnostic";
  like $out, qr/^1\.\.1$/m, "$name: with a plan";
}

done_testing;
