use strict;
use warnings;
use Musicgene;

# make something to start from
my @seeds;
for (0..9) {
  $seeds[$_] = Musicgene->new(20);
  print "$_ : ", ($seeds[$_]->_test_dump)[0], "\n";
  $seeds[$_]->write_file('music'.$_.'.mid');
}

print "Enter number to retain (0-9):";
while (<>) {
  chomp;
  last if /\D/;
  $seeds[0] = $seeds[$_];
  $seeds[0]->write_file('music0.mid');
  print "\n0: ", ($seeds[0]->_test_dump)[0], "\n";
  for (1..9) {
    $seeds[$_] = $seeds[0]->clone; # make some children
    $seeds[$_]->mutate(5);         # modify them a bit
    $seeds[$_]->write_file('music'.$_.'.mid');
    print "$_: ", ($seeds[$_]->_test_dump)[0], "\n";
  }
  print "Enter number to retain (0-9):";
}
