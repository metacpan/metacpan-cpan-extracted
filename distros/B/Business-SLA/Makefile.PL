use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::SLA',
    VERSION_FROM => 'lib/Business/SLA.pm', # finds $VERSION
    AUTHOR       => 'Linda Julien <leira@bestpractical.com>',
    PREREQ_PM	 => {
        Business::Hours => 0
	},
    ABSTRACT     => '',
    SIGN         => 1,
);
