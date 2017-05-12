use strict;
use warnings;

use Astro::Hipparcos;

my $cat = Astro::Hipparcos->new(shift);
my @records;
while (defined(my $rec = $cat->get_record())) {
  push @records, $rec;
}

print "Done reading.\n";
sleep 5;

