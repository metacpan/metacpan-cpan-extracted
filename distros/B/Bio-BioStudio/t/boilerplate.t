#!perl -T

use 5.006;

use Test::More tests => 18;
use English qw(-no_match_vars);
use Carp;

use strict;
use warnings;


sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        || croak "couldn't open $filename for reading: $OS_ERROR";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/Bio/BioStudio.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/BLAST.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Cairo.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Chromosome.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Chunk.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/DB.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Diff.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Exceptions.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Foswiki.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/GBrowse.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Mask.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Megachunk.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/Repository.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/RestrictionEnzyme.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/RestrictionEnzyme/Store.pm');
  module_boilerplate_ok('lib/Bio/BioStudio/RestrictionEnzyme/Seek.pm');


}

