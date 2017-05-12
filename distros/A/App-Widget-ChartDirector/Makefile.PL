
######################################################################
## File: $Id: Makefile.PL,v 1.2 2005/04/13 17:53:58 spadkins Exp $
######################################################################

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#my @programs = <bin/[a-z]*>;

%opts = (
    'NAME'         => 'App-Widget-ChartDirector',
    'DISTNAME'     => 'App-Widget-ChartDirector',
    'VERSION'      => '0.966',
    #'EXE_FILES'    => [ @programs ],
    'PREREQ_PM'    => {
        "App::Options"   => 0,  # option parsing
        "File::Spec"     => 0,  # platform-neutral directory processing
    },
);

######################################################################
# MAKE THE MAKEFILE
######################################################################

WriteMakefile(%opts);

sub MY::postamble {
    return <<EOF;

install ::
	@\$(MOD_INSTALL) cgi-bin   \$(PREFIX)/cgi-bin

EOF
}

