package My::AlienPatch;

use strict;
use warnings;
use Tie::File;

sub main::alien_patch {
  my $newuse = qq{\nuse Alien::SNMP;\n};
  tie my @perlmod, 'Tie::File', 'perl/SNMP/SNMP.pm'
    or die "can't open SNMP.pm: $!";
  for (@perlmod) {
    if (m/use warnings;/) {
      $_ .= $newuse;
      last;
    }
  }
}

1;
