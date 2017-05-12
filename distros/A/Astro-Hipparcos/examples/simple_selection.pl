use strict;
use warnings;
use Astro::Hipparcos;

# An example demonstrating a simple selection
# of stars. The selected subset is written to another
# file.

my $catalog = Astro::Hipparcos->new('hip_main.dat');
my $subsample = Astro::Hipparcos->new('subsample.dat');

while (defined(my $record = $catalog->get_record())) {
  my $parallax = $record->get_Plx();
  my $parallax_err = $record->get_e_Plx();
  next if $parallax == 0;

  if ($parallax_err/$parallax < .1) {
    # relative trig. parallax error smaller than 10%
    $subsample->append_record($record);
  }
}


