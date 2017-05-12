#! perl
use strict;
use warnings;

END {
  # must be before Test::More's END blocks
  BAIL_OUT('Sanity checks failed') if $?;
}
use Test::More tests => 18;

use File::Spec;
use Config; # for %Config
use Time::HiRes qw( gettimeofday tv_interval );

use lib 't/tlib';
use BashRunner 'bash_interactive';


sub main {
  my $have_bash = has_bash_tt(); # 2
  preconds_tt(); # 9

 SKIP: {
    skip "No Bash -- give up", 7 unless $have_bash;

    histzap_tt(); # 2
    interactiveness_tt(); # 5
  }
}


sub has_bash_tt {
  # see that we're talking to something we understand
  my $bash_version = `bash -c 'echo \$BASH_VERSION'`;
  chomp $bash_version;

  my $present = ok($bash_version ne '', 'Bash is installed');

  like($bash_version, qr{^([2-9]|\d{2,})\.\d+}, # >= v2 is a guess
       "bash --version: sane and modern-ish")
    && diag("bash --version: $bash_version");

  return $present;
}

sub preconds_tt {
  # Need PATH during PATH-munge in later tests
  foreach my $k (qw( PATH )) {
    ok(defined $ENV{$k} && $ENV{$k} ne '', "\$$k is set");
  }

  foreach my $k (qw( POSIXLY_CORRECT PROMPT_COMMAND PROMPT_DIRTRIM )) {
    ok(!defined $ENV{$k}, "Bash with \$$k is untested, YMMV");
  }

  # can we find ourself with both hands?
  foreach my $fn (qw( blib/script/psst t/prompt.t )) {
    ok(-f $fn, "$fn is a file");
  }
  is(devino($0), devino('t/00-sane.t'), 'running in there');

  # need our built copy on PATH, PERL5LIB
  my $sep = $Config{path_sep}; # per perlrun(1)
#  like($ENV{PATH}, qr{^[^:]*blib/script/?(:|$)}, 'our blib on $ENV{PATH}');
# hardwired above
  like((join $sep, map { __un8xify($_) } @INC),
       qr{^(t/tlib$sep)([^$sep]+/)?blib/lib/?($sep|$)},
       'our blib on @INC (munged)'); # t/tlib added by 'use lib' above
  like(__un8xify((split /$sep/, $ENV{PERL5LIB})[0]), # first element
       qr{(^|/)blib/lib/?$}, 'our blib at front of $ENV{PERL5LIB} (munged)');
}

sub __un8xify { # make the path look more like a Un*x one
  my ($path) = @_;
  my @path = File::Spec->splitdir($path);
  return join '/', @path;
}


sub histzap_tt {
  # ensure we are not polluting user's history file
  my $home = $ENV{HOME};
  if (!defined $home # e.g. MSWin32
      || $home eq '' || !-d $home) {
    $home = (getpwuid($>))[7];
    diag("\$HOME invalid, falling back to $home for histzap_tt check");
  }
  my $histfn = "$home/.bash_history";
  my $pid = $$;

  like(bash_interactive("echo 'disTincTivecanarycommand+$pid from $0'"),
       qr{^disTincTive.*$pid\b}m, "ran history canary");

 SKIP: {
    skip "no $histfn", 1 unless -f $histfn;
    if (open my $fh, '<', $histfn) {
      my @hit;
      while (<$fh>) {
	push @hit, $_ if /disTincTivecanarycommand.*$pid/;
      }
      is("@hit", '', "$histfn not polluted");
    } else{
      fail("read $histfn: $!");
    }
  }
}


sub interactiveness_tt {
  # see that &bash_interactive works

  is(bash_interactive("echo \$PPID\n", PS1 => '>'),
     qq{>echo \$PPID\n$$\n>exit\n}, "PPID check");

  my $quick_alarm = 0.75; # too quick will cause false fail; slow is tedious
  diag("alarm test - short delay");
  my $t0 = [gettimeofday()];
  my $ans = eval { bash_interactive("sleep 7", maxt => $quick_alarm) } || $@;
  my $wallclock = tv_interval($t0);
  like($ans, qr{Timeout.*waiting for}, "alarm fired (total $wallclock sec)");
  cmp_ok($wallclock, '>', $quick_alarm * 0.7, '  and that alarm waited');
  cmp_ok($wallclock, '<', $quick_alarm * 5.0, '  but did not wait too long');

  local @ENV{qw{ G1 G2 G3 }} =
    ('ABCD goldfish', 'MA goldfish', 'SAR CDBDIs');
  like(bash_interactive(qq{echo \$G1; echo \$G2\necho \$G3\n}),
       qr{ABCD.*MA.*SAR}s, "command sequence");
}


sub devino {
  my ($fn) = @_;
  my @s = stat($fn);
  return @s ? "$s[0]:$s[1]" : "$fn absent";
}


main();
