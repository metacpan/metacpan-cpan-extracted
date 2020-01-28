# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IO-Uncompress-Untar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Chart::Colors') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# testing Next: perl -MChart::Colors -e '$c=new Chart::Colors(); for(my $i=0;$i<5;$i++) { print "$i\t( " . join(", ",$c->Next()) . " )\n"; }'  # correct= ['204,81,81', '127,51,51', '81,204,204', '51,127,127', '142,204,81']

my $c=new Chart::Colors();

my $tst='';
for(my $i=0;$i<5;$i++) { $tst.="$i(" . join(",",$c->Next()) . ") "; }

ok((($tst eq '0(204,81,81) 1(127,51,51) 2(81,204,204) 3(51,127,127) 4(142,204,81) ') || ($tst eq '0(204,81,81) 1(127,50,50) 2(81,204,204) 3(50,127,127) 4(142,204,81) ')), "Next OK $tst");

done_testing();

  # or
  #          use Test::More;   # see done_testing()
  #
  #          require_ok( 'Some::Module' );
  #
  #          # Various ways to say "ok"
  #          ok($got eq $expected, $test_name);
