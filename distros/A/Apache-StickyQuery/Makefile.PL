use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::StickyQuery',
    'VERSION_FROM' => 'lib/Apache/StickyQuery.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More        => 0,
	HTML::StickyQuery => 0.03,
	mod_perl          => 1.21,
	Apache::Filter    => 0,
    },
);
