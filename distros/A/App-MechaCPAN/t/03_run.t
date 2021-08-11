use strict;
use Test::More;

require q[./t/helper.pm];

my $ret;

$App::MechaCPAN::TIMEOUT = 3;
sub run { goto &App::MechaCPAN::run }

# Successful run
is( eval { run $^X, '-e', 'exit 0'; 1 }, 1, 'Can successfully run' );

# Failed run
is( eval { run $^X, '-e', 'exit 1'; 1 }, undef, 'Can successfully fail' );

# Output
my @lines = qw/line1 line2 line3/;
my @output = eval { run $^X, '-e', "print join(qq[\\n], qw[@lines]);" };
is_deeply( \@output, \@lines, 'Result from run is STDOUT' );

# Timeout run
is( eval { run $^X, '-e', 'sleep 10'; 1 }, undef, 'Will timeout without output' );
is( eval { run $^X, '-e', 'sleep 2; print STDERR "\n"; sleep 2;'; 1 }, 1, 'Output resets timeout' );

# Test for output gathering and logging
{
  my $output           = '';
  my $capture          = '';
  my $stderr           = '';
  my $capture_expected = join( qq[\\n], @lines );

  local $App::MechaCPAN::LOGFH;
  local *STDERR;
  local $App::MechaCPAN::VERBOSE = 1;

  open $App::MechaCPAN::LOGFH, '>', \$output;
  open my $capture_fh, '>', \$capture;
  open STDERR, '>', \$stderr;

  eval { run $capture_fh, $^X, '-e', "print join(qq[\\n], qw[@lines]);" };

  unlike( $stderr, qr/$capture_expected/, 'File Handle capture - STDERR does not contain outputted data' );
  unlike( $output, qr/$capture_expected/, 'File Handle capture - Log output does not contain outputted data' );
  like( $capture, qr/$capture_expected/, 'File Handle capture - Capture output does contain outputted data' );

  $output  = '';
  $capture = '';
  $stderr  = '';

  my @output = eval { run $^X, '-e', "print join(qq[\\n], qw[@lines]);" };

  unlike( $stderr,  qr/$capture_expected/, 'Array Capture - STDERR does not contain outputted data' );
  unlike( $output,  qr/$capture_expected/, 'Array Capture - Log output does not contain outputted data' );
  unlike( $capture, qr/$capture_expected/, 'Array Capture - Capture file output does contain outputted data' );
  like( join( "\n", @output ), qr/$capture_expected/, 'Array Capture - Capture output does contain outputted data' );
}

done_testing;
