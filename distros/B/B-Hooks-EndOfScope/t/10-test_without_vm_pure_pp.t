use strict;
use warnings;
use Test::More 0.88;

use B::Hooks::EndOfScope;

plan skip_all => "Tests already executed in pure-perl mode"
  if $INC{'B/Hooks/EndOfScope/PP.pm'};

use Config;
use IPC::Open2 qw(open2);
use File::Glob 'bsd_glob';

# in case the user had it set
$ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION} = '';

# for the $^X-es
$ENV{PERL5LIB} = join ($Config{path_sep}, @INC);

my $has_dh = eval { require Devel::Hide; Devel::Hide->VERSION('0.0007') };
die 'author tests require Devel::Hide for testing the PP path!' if not $has_dh
    and ($ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING});
fail 'smokers require Devel::Hide for testing the PP path!' if not $has_dh
    and $ENV{AUTOMATED_TESTING};

$ENV{DEVEL_HIDE_VERBOSE} = 0 if $has_dh;
$ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION} = 'PP' unless $has_dh;

# rerun the tests under the assumption of no vm at all
my @files = bsd_glob("t/0*.t");
push @files, 'xt/author/00-compile.t' if $ENV{AUTHOR_TESTING};
for my $fn (@files) {

  next if $fn eq 't/00-report-prereqs.t';

  note "retesting $fn";
  my @cmd = (
    $^X,
    $has_dh ? '-MDevel::Hide=Variable::Magic' : (),
    $fn
  );

  # this is cheating, and may even hang here and there (testing on windows passed fine)
  # if it does - will have to fix it somehow (really *REALLY* don't want to pull
  # in IPC::Cmd just for a fucking test)
  # the alternative would be to have an ENV check in each test to force a subtest
  open2(my $out, my $in, @cmd);
  while (my $ln = <$out>) {
    print "   $ln";
  }

  wait;
  ok (! $?, "Wstat $? from: @cmd");
}

done_testing;
