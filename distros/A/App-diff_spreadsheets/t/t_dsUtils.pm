package t_dsUtils;

# Utilities used by App::diff_spreadsheets tests

require Exporter;
use parent 'Exporter';
our @EXPORT = qw(runtest $progname $progpath);

use t_Common; # strict, warnings and lots of stuff
use t_TestCommon qw/:DEFAULT $debug $verbose $silent/; # imports Test2::V0

use Capture::Tiny ();
use FindBin qw/$Bin/;
require PerlIO;

our $progname = "diff_spreadsheets";
our $progpath = "$Bin/../bin/$progname";

sub runtest($$$$$$;@) {
  my ($in1, $in2, $exp_out, $exp_err, $exp_exit, $desc, @extraargs) = @_;
  if (state $first_time = 1) {
    # Capture::Tiny will decode octets from the results according to whatever
    # encoding was set for STDOUT or STDERR, and if not it won't decode.
    # This corrupts wide characters unless enc is pre-set on those handles.
    unless (grep /utf.*8/i, PerlIO::get_layers(*STDOUT)) {
      croak "STDOUT does not have utf8 or encoding(UTF-8) enabled";
    }
    unless (grep /utf.*8/i, PerlIO::get_layers(*STDERR)) {
      croak "STDERR does not have utf8 or encoding(UTF-8) enabled";
    }
    $first_time = 0;
  }
  
  my $show_output = $debug || ($exp_err eq "" && $exp_out eq "");

  unshift @extraargs, "--output-encoding", "UTF-8";
  unshift @extraargs, "--verbose" if $verbose;
  unshift @extraargs, "--debug" if $debug;
  #unshift @extraargs, "--silent" if $silent;
  # Suppress waiting-for-lockfile messages
  unshift @extraargs, "--silent" unless $verbose or $debug;
confess "unexpected" if $verbose or $debug;

  # Translate *nix /path to Windows \path
  $in1 = path($in1)->canonpath;
  $in2 = path($in2)->canonpath;
  
  my ($out, $err, $wstat);
  if ($show_output) {
    ($out, $err, $wstat) = Capture::Tiny::tee { 
      run_perlscript $progpath, @extraargs, $in1, $in2;
    };
  } else {
    ($out, $err, $wstat) = Capture::Tiny::capture { 
      run_perlscript $progpath, @extraargs, $in1, $in2;
    };
  }

  # We can only use the 'goto &somewhere' trick for one check; so other
  # check(s) must be done here and will unhelpfully report the file/linenum 
  # in here; so include the caller's file/lno in the description.
  my ($file, $lno) = (caller(0))[1,2];
  $file = basename($file);
  my $diag = $show_output ? "" : "OUT:<<$out>>\nERR:<<$err>>\n";
  
  is($wstat, ($exp_exit << 8), sprintf("(WSTAT=0x%x)",$wstat)." ${file}:$lno $desc", $diag);

  # Don't check STDERR if 'debug' is enabled, as it may be full of tracing
  if (!$debug) {
    # Similarly if 'verbose' is enabled *unless* the caller expects something
    if (!$verbose || $exp_err ne "") {
      like($err, $exp_err, "(STDERR) ${file}:$lno $desc", $diag);
    }
  }

  @_ = ($out, $exp_out, "(STDOUT) $desc", $diag);
  goto &Test2::V0::like; 
}

1;
