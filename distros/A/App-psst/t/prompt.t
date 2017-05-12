#! perl
use strict;
use warnings;
use Test::More tests => 10;
use YAML 'Dump'; # gives nice \e (etc.) representation of control codes
use Config; # for %Config

use lib 't/tlib';
use BashRunner 'bash_interactive';


sub main {
  $ENV{PATH} = "blib/script$Config{path_sep}$ENV{PATH}"; # not set by prove or Makefile.PL

  # prevent influence from real local::lib
  my @LLvars = qw{PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT MODULEBUILDRC};
  delete @ENV{@LLvars};

  prompt_tt(); # 7
  pidburn_tt(); # 3
}


sub prompt_tt {
  local $ENV{HOME} = 't/home-ps1';
  local $ENV{PS1_FROM_TEST} = 'here> '; # nb. trailing space is lost
  # in t/bashrc because we allow absence of that arg

  ###  See that we get initialised
  #
  # --rcfile t/bashrc doesn't?
  # but sourcing our config at the prompt works
  my $run = qq{. t/bashrc\necho showvar::\$BASHRC_FOR_TESTING::\n};
  like(bash_interactive($run),
       qr{^here>echo.*\nshowvar::seen::\nhere>exit\n\z}m,
       'see our bashrc, use our prompt');

  # See that the config in fake $HOME is used
  # With no local::lib, no other prompt marks
  my @ll_marks = (qr{^LL\) }m, qr{^l:l=}m);
  delete $ENV{PS1_FROM_TEST};
  my $out2 = bash_interactive($run);
  like($out2, qr{\ncfgd> echo}m, 'take PS1_old from home-ps1');
  does_qrs($out2, \@ll_marks, 0, 'out2 (non-LL)');

  $ENV{HOME} = 't/home-substing';
  local $ENV{TERM} = 'ansi'; # else Bash may try to compensate
  $run = qq{. t/bashrc\nPERL_LOCAL_LIB_ROOT=/twang/fump\n};
  my $out3 = bash_interactive($run, PS1 => '>>');
  does_qrs(deansi($out3), \@ll_marks, 2, 'out3 (+LL deansi)');

  # Hardcoding the output from the ANSI code generator is sure to be a
  # maintenance burden...  change it Later.
  is(Dump($out3), Dump(<<"LITERAL"), 'out3 (+LL literal)');
>>. t/bashrc
>>PERL_LOCAL_LIB_ROOT=/twang/fump
\e7\r\e[3B\e[2K\e[B\e[2Kl:l=\e[32m/twang/fump\e8\e[32mLL)\e[0m >>exit
LITERAL
  # Did supply PS1 because we test the whole string, and don't want to
  # have to strip off local prompt strings.  That PS1 overrides the
  # config.

  # Takes env & does substitution
  local $ENV{PERL_LOCAL_LIB_ROOT} = "/twang/fump$Config{path_sep}/path/to/stuff";
  $run = qq{. t/bashrc\n\n};
  my $out4 = bash_interactive($run);
  does_qrs(deansi($out4), \@ll_marks, 2, 'out4 (+LL deansi)');
  like(deansi($out4), qr{^l:l=/twang/fump : PT/stuff$}m, 'out4 (substituted, deansi)');
}

sub does_qrs {
  my ($got, $regexps, $want_hitcount, $name) = @_;

  my @hit;
  foreach my $re (@$regexps) {
    my @cap = $got =~ $re;
    push @hit, [ $re, @cap ] if @cap;
  }
  is(scalar @hit, $want_hitcount, $name)
    or diag Dump({ got_hits => \@hit, got_text => $got, want_hits => $want_hitcount });
}


sub pidburn_tt {
  # does Bash burn pids?
 SKIP: {
    my $pidseq = pidseq_subtest();
    my $skip;
    $skip = 'pid allocation appears to be randomised' if $pidseq =~ /^rand/;
    diag($skip) if $skip; # I want to see this skip in smoketests
    skip $skip, 3 if $skip;

    like($pidseq, qr{^sequential=1 }, 'Unconfigured, Bash does not burn PIDs');
    local $ENV{PERL_LOCAL_LIB_ROOT} = "/path/to/foo$Config{path_sep}/path/to/bar";
  TODO: {
      local $TODO = 'not implemented in psst(1)';
      like(pidseq_subtest(), qr{^sequential=1 },
	   "don't burn pids unless PS1_substs");
    }
    local $ENV{HOME} = 't/home-substing';
    like(pidseq_subtest(), qr{^promptburn=2 },
	 'it seems we must burn pids to do PS1_substs');
  }
}


# Attempt to determine whether the shell is forking per prompt.
# Likely to be flaky.
#
# Likely outcomes,
#   broken: can't see pids
#   sequential=1 <n>: Perl eats one per line
#   promptburn=2 <n>: Bash & Perl each eat one per line
#   random: no discernable pattern (e.g. on OpenBSD)
#
# PID wrap should not cause problems.  Fast PID churn from other
# sources might require larger $N to get non-weird results.
sub pidseq_subtest {
  my ($N) = @_;
  my $retrying = defined $N;
  $N ||= 50;

  # print many prompts, examine pid issued to the process requested
  my $run = ". t/bashrc\n".("perl -e 'print qq{pid:\$\$\\n}'\n" x $N);
  my $txt = bash_interactive($run, maxt => $N / 5);

  my @pid = ($txt =~ m{^pid:(\d+)$}mg);
  if ($N != @pid) {
    return sprintf('broken: see %d/%d pid: lines', scalar @pid, $N);
  }

  # Very basic stats.  Output elements are
  #
  #   "$diff1 <$count_significant>"
  #   "($diff2 x$count_insignificant)"
  my %hist; # key = line-to-line difference in PID; value = event count
  while ($#pid) {
    my $diff = $pid[1] - (shift @pid);
    $hist{$diff} ++;
  }

  $N --; # we are now interested in differences between PIDs; sample of these is smaller
  my @hist; # output elements
  my @diff_sig; # $diff which are significant
  my $thres = sqrt($N);
  foreach my $diff (sort {$hist{$b} <=> $hist{$a}} keys %hist) {
    my $count = $hist{$diff};
    my $sig = $count / $thres;
    $count .= "/$N" if !@hist; # show total on first ele
    my $ele = $sig > 1 ? "$diff <$count>" : "($diff x$count)";
    push @diff_sig, $diff if $sig > 1;
    push @hist, $ele;
  }
  my $raw = join ', ', @hist;
  $raw .= sprintf('; thres=%.2f', $thres);

  # Summarise
  if (0 == @diff_sig) {
    return "random: $raw";
  } elsif (1 == @diff_sig) {
    my $diff = $diff_sig[0];
    my $type = { 1 => 'sequential', 2 => 'promptburn' }->{$diff} || 'weird';
    return "$type=$raw";
  } else {
    if ($retrying) {
      return "weird (not unimodal..  not enough trials? system busy?): $raw";
    } else {
      diag("weird pidseq ($raw) - going to try harder");
      return pidseq_subtest($N * 10);
    }
  }
}

sub deansi { # removes ANSI/vt100 codes we use
  my ($txt) = @_;
  $txt =~ s{\x1b\[([0-9;]*)m}{dv(c => $1)}eg; # colour
  $txt =~ s{\x1b\[([0-2]?)K}{dv(e => $1)."\n"}eg; # erase
  $txt =~ s{\x1b([78])}{dv(sr => $1)."\n"}eg; # save/restore
  $txt =~ s{\x1b\[(\d*[A-D])}{dv(udrl => $1)."\n"}eg; # up/down/right/left
  $txt =~ s{\r*\n+[\r\n]*}{\n}g; # compaction to visible linebreaks
  return $txt;
}
sub dv { # deansi: hackable verbosity, for debugging; breaks tests
  return $ENV{TEST_DEANSI_SHOW} ? "(($_[0] => $_[1]))" : '';
}

main();
