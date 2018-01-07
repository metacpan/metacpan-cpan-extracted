use strict;
use Test::More;

use Capture::Tiny qw(capture);
use File::Temp qw/ tempdir /;
use Cwd;

use subs qw/test_run/;
my $cwd = Cwd::cwd();


sub test_run {
  my ($test_name, $status, $search, @args) = @_;
  my($stdout, $stderr, $exit) = capture {
    system $^X, "$cwd/script/cpane", @args;
  };

  my $msg = '';

  if( ($status eq 'ok') != (0 == $exit) ) {
    $msg = "execution status ($exit) is wrong\n";
  }

  my $result = $status eq 'ok' ? $stdout : $stderr;
  if( -1 == index($result, $search) ) {
    $msg .= "search string: '$search' not found\n";
  }

  if( $msg ) {
    $msg .= "stdout: $stdout\n" if $stdout;
    $msg .= "stderr: $stderr\n" if $stderr;
  }

  ok !$msg, $test_name;
} 


my $result;
my $tmpdir = tempdir( CLEANUP => 1 );


chdir $tmpdir;

mkdir "$tmpdir";

test_run 'folder "./local" is required',
  error => "There is no folder 'local' in current dir",
  'echo echo must exit with error';

mkdir "$tmpdir/local";

test_run 'script or command is required',
  error => "Script or execuble may be with args required";

test_run 'env is configured to load libraries',
  ok => "$tmpdir/local/lib",
  'echo $PERL5LIB';

test_run 'env is configured to execute binary',
  ok => "$tmpdir/local/bin",
  'echo $PATH';

chdir $cwd;

done_testing();

