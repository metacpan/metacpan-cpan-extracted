use strict; use warnings FATAL => 'all';

BEGIN {
  # I don't know what the proper way to make piped open happy on Windows is,
  # and I don't have machines to test on. Patches welcome:
  if ($^O eq 'MSWin32') {
    require Test::More;
    Test::More::plan(skip_all =>
      'Skipping cmd tests because we are RUNNING_IN_HELL'
    );
  }
}

use Test::More;
use Capture::Tiny 'capture';

use Config;
my $perl = $Config{perlpath};
if ($^O ne 'VMS') {
  $perl .= $Config{_exe} unless $perl =~ /$Config{_exe}$/i
}


open my $origfh, '<', 'Changes' or die $!;
my $changes = do { local $/; <$origfh> };
chomp $changes;
close $origfh or warn $!;


{
  my ($out, $err, $status) = capture {
    system( $perl, 'bin/z85_convert', '--help' )
  };

  like $out, qr/z85_convert/, '--help output looks ok';
  ok !$err, 'no stderr on --help';
}

{
  # Encoding from file (no --file)
  my ($z85, $err, $status) = capture {
    system( $perl, 'bin/z85_convert', 'Changes' )
  };
  ok !$err, 'no stderr on z85 file encode';
  ok $z85,  'z85 file encode produced output';

  # Encoding from file (with --file)
  my ($f_z85, $f_err, $f_status) = capture {
    system( $perl, 'bin/z85_convert', '--file', 'Changes' )
  };
  ok !$f_err, 'no stderr on z85 file encode (--file)';
  cmp_ok $f_z85, 'eq', $z85, 'z85 file encode with --file ok';

  # Decoding from stdin
  my ($raw, $r_err, $r_status) = capture {
    open my $fh, '|-', $perl, 'bin/z85_convert', '--decode'
      or die $!;
    print $fh $z85;
    close $fh or warn $!;
  };
  ok !$r_err, 'no stderr on stdin decode';

  chomp $raw;
  cmp_ok $raw, 'eq', $changes, 'roundtripped ok';
}

{
  # Encoding from file (with --wrap)
  my ($f_z85, $f_err, $f_status) = capture {
    system( $perl, 'bin/z85_convert', '--wrap', '76', 'Changes' )
  };
  ok !$f_err, 'no stderr on z85 file encode (--wrap 76)';

  my ($raw, $r_err, $r_status) = capture {
    open my $fh, '|-', $perl, 'bin/z85_convert', '--decode'
      or die $!;
    print $fh $f_z85;
    close $fh or warn $!;
  };

  chomp $raw;
  cmp_ok $raw, 'eq', $changes, 'roundtripped with --wrap ok';
}

done_testing
