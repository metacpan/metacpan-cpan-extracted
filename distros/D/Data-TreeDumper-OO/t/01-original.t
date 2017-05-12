# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };

use Data::TreeDumper;
use Data::TreeDumper::OO;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$Data::TreeDumper::Maxdepth = 1 ;

my $dumper = new Data::TreeDumper::OO(MAX_DEPTH => 1) ;

$dumper->UseAnsi(1) ;
$dumper->SetMaxDepth(-1) ;

print $dumper->Dump($dumper, $dumper) ;

ok(2); 
