#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Temp ();
use Test::More;

use lib $FindBin::Bin.'/lib';

use BriefingTest qw( run_cli sandbox );

my $box = sandbox();

# Child programs live in script files: quoting `-e` code is unreliable on
# native Windows command lines.
my $scripts = File::Temp->newdir( CLEANUP => 1 );
sub child_script {
  my ( $name, $code ) = @_;
  my $file = "$scripts/$name.pl";
  open my $fh, '>', $file or die "cannot write $file: $!";
  print {$fh} $code;
  close $fh or die "cannot close $file: $!";
  return $file;
}
my $echo_script = child_script( 'echo', <<'CODE' );
binmode STDIN;
binmode STDOUT;
binmode STDERR;
local $/;
print scalar <STDIN>;
print STDERR "e";
exit 3;
CODE
my $sleep_script = child_script( 'sleep', "sleep 300;\n" );

my $echo = run_cli(
  sandbox => $box,
  argv    => [ $^X, $echo_script ],
  input   => "hello\n",
);
is_deeply(
  $echo,
  { stdout => "hello\n", stderr => 'e', exit_code => 3 },
  'run_cli feeds stdin from a file and captures both streams and the exit code',
);

my $started = time;
my $ok = eval {
  run_cli(
    sandbox => $box,
    argv    => [ $^X, $sleep_script ],
    timeout => 2,
  );
  1;
};
my $elapsed = time - $started;
ok(!$ok, 'run_cli dies when the child outlives its timeout');
like($@, qr/timed out after 2s/, 'the failure names the timeout');
cmp_ok($elapsed, '<', 30, 'the sleeping child was killed, not waited for');

done_testing;
