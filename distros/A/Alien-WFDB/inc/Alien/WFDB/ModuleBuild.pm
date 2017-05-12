package Alien::WFDB::ModuleBuild;

use strict;
use warnings;
use base qw( Alien::Base::ModuleBuild );
use FindBin ();

sub new {
  my $class = shift;
  return $class->SUPER::new(@_);
}

package
  main;

use File::Spec;

sub alien_patch {
	# the -no-docs tarball does not have a doc directory, but the build
	# script still looks for one --- so we create an empty one if it
	# doesn't exist and add stub Makefile (with 'install' and 'clean'
	# targets)
	unless( -d 'doc' ) {
		mkdir 'doc';
		open my $makefile, '>', File::Spec->catfile('doc','Makefile') or die "could not write stub makefile";
		print $makefile <<END
install:

clean:
END
	}
}

1;
