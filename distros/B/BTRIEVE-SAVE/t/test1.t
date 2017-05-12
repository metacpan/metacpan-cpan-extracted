#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

##use lib '.','./t';	# for inheritance and Win32 test
 use lib './blib/lib','../blib/lib','./lib','../lib','..';
# can run from here or distribution base

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use BTRIEVE::SAVE;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Added tests should have an comment matching /# \d/
# If so, the following will renumber all the tests
# to match Perl's idea of test:
# perl -pi.bak -e 'BEGIN{$i=1};if (/# \d/){ $i++};s/# \d+/# $i/' test1.t

############################################

use Cwd; 

my $dir = getcwd;
use strict;
use vars qw/$TEST/;
my $tc = 2;		# next test number

use strict;
use File::Compare;
## use Data::Dumper;

sub out_cmp {
    my $outfile = shift;
    my $reffile = shift;
    if (-s $outfile && -s $reffile) {
        return is_zero (compare($outfile, $reffile));
    }
    printf ("not ok %d\n",$tc++);
}

sub is_zero {
    my $result = shift;
    if (defined $result) {
        return is_ok ($result == 0);
    }
    printf ("not ok %d\n",$tc++);
}

sub is_ok {
    my $result = shift;
    printf (($result ? "" : "not ")."ok %d\n",$tc++);
    return $result;
}

sub is_bad {
    my $result = shift;
    printf (($result ? "not " : "")."ok %d\n",$tc++);
    return (not $result);
}

my $stem1 = "f1";
my $stem2 = "f2";

my $testdir = "t";

if (-d $testdir) {
    chdir $testdir;
}


my $naptime = 0;	# pause between output pages
  if (@ARGV) {
      $naptime = shift @ARGV;
      unless ($naptime =~ /^[0-5]$/) {
  	die "Usage: perl test?.t [ page_delay (0..5) ]";
      }
  }

  unlink 'output.txt', 'output.html', 'output.xml', 'output.isbd',


$BTRIEVE::SAVE::TEST = 1; #

my $btr = BTRIEVE::SAVE->new("f1ref.std");
$btr->rdb_to_save("f1ref.rdb","f1.savout","f1rdb.errout",
		       'ZZ','VAR','<TAB>','<RET>');
                 
1; #for those who want to examine structures in the debugger.

out_cmp("f1ref.sav","f1.savout");               # 2
out_cmp("f1rdbref.err","f1rdb.errout");         # 3



$btr->save_to_rdb("f2.rdbout","f2ref.sav","f2sav.errout",
		       'ZZ','VAR','<TAB>','<RET>');

1; #for those who want to examine structures in the debugger.

out_cmp("f2ref.rdb","f2.rdbout");               # 4
out_cmp("f2savref.err","f2sav.errout");         # 5
