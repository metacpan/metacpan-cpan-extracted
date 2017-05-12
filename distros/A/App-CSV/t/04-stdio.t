#!perl -w

# Check default stdio works from the command line.

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
BEGIN {
  eval "use IPC::Run qw(run); 1" or do {
    plan skip_all => "Please install IPC::Run";
    exit 0;
  };
  plan tests => 8;
}

our $csv_bin   = File::Spec->catfile($Bin, '..', 'bin', 'csv');
my $input = qq("1",2,"3");
my $expected_output = qq(1,2,3\n);

test_stdio('--input' => '-', '--output' => '-');
test_stdio('--input' => '-',                  );
test_stdio(                  '--output' => '-');
test_stdio(                                   );

sub test_stdio {
  my(@opts) = @_;

  my @args = ($^X, libs(), $csv_bin, @opts);
  diag("run @args");
  run \@args, \$input, \my $actual_output, \my $stderr or die "run: $?";

  is($actual_output, $expected_output,
      "actual commandline invocation produces correct results");
  is($stderr, "", "nothing on stderr");
}

sub libs { map { ('-I' => $_) } @INC }
sub slurp { local $/; local @ARGV = pop; <> }

