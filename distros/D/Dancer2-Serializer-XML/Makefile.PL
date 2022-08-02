use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Dancer2::Serializer::XML',
    VERSION_FROM      => 'lib/Dancer2/Serializer/XML.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM    => {
		"Class::Load" => 0,
		"Moo" => 0
    },
    TEST_REQUIRES    => {
		"Plack::Test" => 0,
		"Test::More" => 0,
		"Module::Runtime" => 0
    },
    ABSTRACT_FROM     => 'lib/Dancer2/Serializer/XML.pm', # retrieve abstract from module
    AUTHOR            => 'Ian Gibbs <igibbs@cpan.org>',
    LICENSE           => 'gpl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
