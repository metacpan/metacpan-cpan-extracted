#!perl

use strict;
use Test::More; # Don't know ahead of time how many
                # modules we have to test.
use File::Find; # To find modules to test.

my @modules; # This will get set in the &wanted subroutine.

# Scan through blib/ looking for modules.
find( { wanted => \&wanted,
        no_chdir => 1,
      },
      "blib" );

# Set the number of tests we're going to do.
plan tests => scalar( @modules ) + 1;

# Loop through each module and check if require_ok works.
foreach my $module ( @modules ) {
  require_ok( $module );
}

# Test the FINDOFF method separately, only if we have the Starlink
# modules installed. Test the availability of Starlink::Config, and
# assume that if that's installed then they're all installed and we
# can test the compilation of FINDOFF.
eval{ require Starlink::Config; };
SKIP: {
  skip "Starlink Perl modules not installed", 1 if $@;
  require_ok( "Astro::Correlate::Method::FINDOFF" );
}

# This determines whether we are interested in the module
# and then stores it in the array @modules

sub wanted {
  my $pm = $_;

  # is it a module
  return unless $pm =~ /\.pm$/;

  # Special case: return if this is FINDOFF.
  return if $pm =~ /FINDOFF/;

  # Remove the blib/lib (assumes unix!)
  $pm =~ s|^blib/lib/||;

  # Translate / to ::
  $pm =~ s|/|::|g;

  # Remove .pm
  $pm =~ s/\.pm$//;

  push(@modules, $pm);
}
