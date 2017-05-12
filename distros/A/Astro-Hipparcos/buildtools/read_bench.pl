use strict;
use warnings;

use Astro::Hipparcos;

my $cat = Astro::Hipparcos->new(shift);
while (defined(my $rec = $cat->get_record())) {

}


