package t::runtests;
use t::lib;
use t::runtests;

use Getopt::Long;
# sigh. Test::Deep exports reftype, blessed (and much more), so be careful when importing
# them from Scalar::Util. okay here since we don't use Test::Deep
# use Scalar::Util qw(looks_like_number reftype blessed);
use Scalar::Util qw(looks_like_number);
use File::Basename qw(fileparse);
use File::Spec;
use Carp;
use Test::More;
use TAP::Harness;
# use TAP::Formatter::Console; 
use TAP::Parser::Aggregator;
use Hash::AutoHash::Args;
use Exporter();
use strict;

our @ISA=qw(Exporter);
our @EXPORT=qw(runtests_main runtests runtests_exact testdir);

# runtests_main
# 'main' function to run all tests in subdirectory
sub runtests_main {
  my($details,$nested,$basenum);
  GetOptions ('details=i'=>\$details,'nested=i'=>\$nested,'basenum=s'=>\$basenum);
  $nested=1 if !defined $nested && defined $basenum; # basenum implies nested
  $details=1 if !defined $details && $nested;        # nested implies details
  my($script,$testdir,$skip)=fileparse($0);
  my $ok=runtests({testcode=>1,details=>$details,nested=>$nested,basenum=>$basenum});
  ok($ok,$script);
  done_testing();
}

# runtests
#   runs all tests in test directory, with order modified by optional arguments
#   if 1st arg is HASH, contains parameters
#      details  show details of subtests
#      nested   being run as nested tests, so don't print summary
#      exact    run exactly and only the given tests in given order
#               default unless testcode or testdir set
#      testcode scriptname encodes subdirectory in which tests reside
#      testdir  subdirectory in which tests reside
#   with no remaining arguments, tests run in alphabetic order
#   remaining argument can be list of 'special' tests to be run in order given or 
#   hash of test=>count for tests that must be repeated
#  
#   special tests are spliced into list of all tests in the alphabetically correct
#   position

# runtests_exact
#   argument is list of tests. these tests are run in given order

# CAUTION: don't import reftype from Scalar::Util because Test::Deep exports it with prototype
sub runtests {_runtests('HASH' eq Scalar::Util::reftype($_[0])? shift: {},\@_);}
sub runtests_exact {
  my $params='HASH' eq Scalar::Util::reftype($_[0])? shift: {};
  $params->{exact}=1;
  _runtests($params,\@_);
}
sub testdir {
  my($params)=@_;
  $params=new Hash::AutoHash::Args $params;
  my($script,$testdir,$skip)=fileparse($0);
  if ($params->testcode) {
    # use word after digits (cases like autodb.051.Table.t) or
    # script basename (cases like autodb.099.docs.t)
    my $testcode;
    ($testcode)=$script=~/\d+\.([[:upper:]]\w*)\.t$/ or ($testcode)=$script=~/^(.*)\.t$/;
    $testdir=$testdir.$testcode.'/';
  } elsif ($params->testdir) {
    $testdir=$testdir.$params->testdir;
    $testdir.='/' unless $testdir=~/\/$/;
  } else {
    $params->exact(1);
  }
  $testdir;
}
sub _runtests {
  my($params,$files_or_array)=@_;
  $params=new Hash::AutoHash::Args $params;
  my($script,$testdir,$skip)=fileparse($0);
  if ($params->testcode) {
    # use word after digits (cases like autodb.051.Table.t) or
    # script basename (cases like autodb.099.docs.t)
    my $testcode;
    ($testcode)=$script=~/\d+\.([[:upper:]]\w*)\.t$/ or ($testcode)=$script=~/^(.*)\.t$/;
    $testdir=$testdir.$testcode.'/';
  } elsif ($params->testdir) {
    $testdir=$testdir.$params->testdir;
    $testdir.='/' unless $testdir=~/\/$/;
  } else {
    $params->exact(1);
  }
  my(@dirfiles,@testfiles);
  my $i=0;			# index into @testfiles, preserved across loops
  my %seen;			# holds files added to @out from input lists
  if ($params->exact) { # use testfiles as given
    @testfiles=@{$files_or_array};
  } else {
    opendir(DIR,$testdir) or confess "Cannot read test directory $testdir: $!";
    @dirfiles=sort grep /^[^.].*\.t$/,readdir DIR;
    closedir DIR;
    if (@$files_or_array) {
      $files_or_array=[$files_or_array] unless ('ARRAY' eq ref $files_or_array->[0]);
      for my $files (@$files_or_array) {
	if (looks_like_number($files->[1])) { # argument looks like hash of test=>count
	  my %repeat=@$files;
	  push(@testfiles,map {($_) x ($repeat{$_}||1)} keys %repeat);
	  @seen{keys %repeat}=(1)x(keys %repeat);
	} else {		   # splice given files into @testfiles
	  my @files=map {/^(\S+)/} @$files; # strip off any args
	  @seen{@files}=(1)x@files;
	  for(; $i<@dirfiles; $i++) { # 1st loop gets files before specials
	    last if $seen{$dirfiles[$i]};
	    push(@testfiles,$dirfiles[$i]);
	  }
	  push(@testfiles,@$files); # add in given files
	  for(; $i<@dirfiles; $i++) { # skip dirfiles we've already processed
	    last unless $seen{$dirfiles[$i]};
	  }
	}
      }
    }
    # add in files after last given ones (or all files if $files_or_array empty
    push(@testfiles,@dirfiles[$i..$#dirfiles]);
  }
  # remove any testfiles in 'skip'
  if (my $skip=$params->skip) {	# can be single test or ARRAY
    $skip=[$skip] unless ref $skip;
    $skip={map {$_=>$_} @$skip};
    @testfiles=grep {!$skip->{$_}} @testfiles;
  }
  # NG 09-03-19: Test::Harness no longer allows repeated running of same tests w/o
  #              jumping through some hoops. sigh...
  #              $i and [] in 'map' below are the hoops
  my $i=0;
  my $basenum=$params->basenum;
  $basenum.='.' if defined $basenum;
  @testfiles=map {File::Spec->catfile($testdir,$_)} @testfiles;
  @testfiles=map {[$_,$basenum.sprintf("%03d",++$i)." $_"]} @testfiles;

  # switches=>undef is probably unnecessary
  # verbosity=>0 is normal, -3 is silent (only prints failures)
  my $harness=new TAP::Harness
    ({switches=>undef,lib=>['blib/lib','blib/arch'],verbosity=>$params->details? 0: -3,
     parser_class=>'t::tap',
     });
  # NG 10-01-05: trying to make nested tests work better
  unless ($params->nested) {	# do it the old way
    $harness->runtests(@testfiles)->all_passed;
  } else {
    # my $formatter   = TAP::Formatter::Console->new;
    my $agg=new TAP::Parser::Aggregator;
    $agg->start();
    $harness->aggregate_tests($agg,(@testfiles));
    $agg->stop();
    $agg->all_passed;
    # $formatter->summary($agg);
  }
  
# The calling program needs to do the 'ok' and 'done_testing', to keep 
# plans in synch and Test::More happy
#    ok($result,$script);
#    done_testing();
# I'm undecided as to whether tests that show details should do a final 'ok'
#   (code below turns this off - should replace 2 lines above)
# this is needed for tests to be used recursively. 
# but when used as top level tests, it causes a confusing final '1..1' message
# I don't see a way to make this decision automatically...
# 
#   unless ($params->details) {
#     require Test::More;
#     import Test::More;
#     ok($result,$script);
#     done_testing();
#   }
}

1;
