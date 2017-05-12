package t::Build;
use strict;
use File::Basename qw(fileparse);
use File::Spec;
use TAP::Harness;
use TAP::Formatter::Console;
use TAP::Parser::Aggregator;
use base qw(Module::Build);

BEGIN {
  $^W = 0;  # turn off warnings
}

# probably not needed anymore
sub harness_switches { # turn off -w in Test::Harness
  shift->{properties}{debugger} ? qw(-d) : qw(-X);
}
# in case Build.PL forgets to say 'use_tap_harness =>1'
sub run_test_harness {shift->run_tap_harness;}

# run simple (non-compound) tests with verbosity=0 (normal), but compound tests with verbosity=1
sub run_tap_harness {
  my($self,$tests)=@_;
  my @testfiles;
  my $libs=[File::Spec->catdir(qw(blib lib)),File::Spec->catdir(qw(blib arch))];
  my $fmt=new TAP::Formatter::Console;
   my $agg=new TAP::Parser::Aggregator;
  $agg->start();
  # switches=>undef is probably unnecessary
  my $harness=new TAP::Harness
    ({switches=>undef,lib=>$libs,parser_class=>'t::tap',});

  for my $i (0..@$tests-1) {
    my $testnum=sprintf("%03d",$i);
    my $test=$tests->[$i];
    my $testargs;
    my($base,$dir,$sfx)=fileparse($test,'.t');
    my $possible_dir=File::Spec->catdir($dir,$base);
    if (-d $possible_dir) {	# directory exists so it's a compound test
      $harness->verbosity(1);
      $testargs=" --basenum=$testnum";
    } else {			# simple test
      $harness->verbosity(0);
    }
    $harness->aggregate_tests($agg,[$test.$testargs,"$testnum $test"]);
    # push(@testfiles,[$test.$testargs,"$testnum $test"]);
  }
  # $harness->runtests(@testfiles);
  $agg->stop();
  $fmt->summary($agg);
  
  # NG 10-02-26: in new versions of Module::Build, method returns $agg
  $agg
}

1;
