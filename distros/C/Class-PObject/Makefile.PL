

# Makefile.PL,v 1.18 2003/11/06 01:35:34 sherzodr Exp

use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME	=> 'Class::PObject',
    VERSION_FROM=> 'PObject.pm',
    #VERSION	=> '2.07_fix02',
    PREREQ_PM	=> {
	    'Storable'      => 0,
	    'IO::Dir'       => 0,
	    'Test::More'    => 0,
	    'Log::Agent'    => 0,
        'File::Spec'    => 0,
        'File::Path'    => 0,
        'File::Basename'=> 0
    },
    ABSTRACT	=> "Simple framework for programming persistent objects",
    AUTHOR	=> "Sherzod B. Ruzmetov <sherzodr\@cpan.org>"
);



package MY;
sub postamble {
	return <<'TAG';
realclean::
	$(RM_RF) data
	$(RM_RF) core.*
TAG
}

sub libscan {
	my (undef, $path) = @_;
	return '' if $path =~ m/CVS/;
	return $path
}

