# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Data::Iterator::EasyObj;

my ($fields2,$data2) = (
		      [ 'subAA', 'subBB',],
		      [ [ 'XXX', 'YYY'], [ 'XXXX', 'YYYY' ],  ],
		     );
my $iterator2 = Data::Iterator::EasyObj->new($data2,$fields2);

my $data = [
             [ 'AAAA', 'test foo A', '1111', $iterator2 ],
             [ 'BBBB', 'test foo B', '2222', $iterator2 ],
             [ 'CCCC', 'test foo C', '3333', $iterator2 ],
             [ 'DDDD', 'test foo D', '4444', $iterator2 ],
             [ 'AAA2', 'test foo A', '1111', $iterator2 ],
             [ 'BBB2', 'test foo B', '2222', $iterator2 ],
             [ 'CCC2', 'test foo C', '3333', $iterator2 ],
             [ 'DDD2', 'test foo D', '4444', $iterator2 ],
           ];
my $fields = [ 'Name', 'About' ,'Value', 'Loop' ];
my $iterator = Data::Iterator::EasyObj->new($data,$fields);

my $string;
$iterator->offset(2);
$iterator->limit(4);

while ($iterator->next) {
  $iterator->add_column('Extra');
  $iterator->add_value('Extra','extra stuff here');
  print "\n-----------\n";
  print "Name : ", $iterator->Name(), " About : ", $iterator->About(), " value : ", $iterator->Value ,"\n";
  while ($iterator->Loop()->next) {
    print " :: ", $iterator->Loop()->subAA(), " , " , $iterator->Loop()->subBB() , "\n";
  }
  print " extra : ", $iterator->Extra() , "\n";
  print "\n";
}

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

