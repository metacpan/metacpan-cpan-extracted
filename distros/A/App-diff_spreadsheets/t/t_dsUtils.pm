package t_dsUtils;

# Utilities used by App::diff_spreadsheets tests

require Exporter;
use parent 'Exporter';
our @EXPORT = qw(runtest $progname $progpath);

use t_Common; # strict, warnings and lots of stuff
use t_TestCommon qw/:DEFAULT $debug $verbose $silent/; # imports Test::More

use Capture::Tiny ':all';
use FindBin qw/$Bin/;

our $progname = "diff_spreadsheets";
our $progpath = "$Bin/../bin/$progname";

sub runtest($$$$$$;@) {
  my ($in1, $in2, $exp_out, $exp_err, $exp_exit, $desc, @extraargs) = @_;
  #unshift @extraargs, "--silent" if $silent;
  unshift @extraargs, "--verbose" if $verbose;
  unshift @extraargs, "--debug" if $debug;
  my ($out, $err, $wstat) = capture{ run_perlscript $progpath, @extraargs, $in1, $in2 };
  my @m;
  if (ref $exp_out) {
    push @m, "stdout wrong (!~ $exp_out); GOT:\n$out" if $out !~ /$exp_out/;
  } else {
    push @m, "stdout wrong (ne '$exp_out'); GOT:\n$out" if $out ne $exp_out;
  }
  if (ref $exp_err) {
    push @m, "stderr wrong (!~ $exp_err); GOT:\n$err" if $err !~ /$exp_err/;
  } else {
    push @m, "stderr wrong (ne '$exp_err'); GOT:\n$err" if $err ne $exp_err;
  }
  if ($wstat != ($exp_exit << 8)) {
    push @m, "exit status wrong (not $exp_exit); GOT ".sprintf("0x%x",$wstat)
  }
  if (@m) {
    my ($lno) = (caller(0))[2];
    diag sprintf("%s at line %d", join(";\n  ",@m), $lno);
  }
  @_ = (@m==0, $desc);
  goto &Test::More::ok
}

1;
