use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBIx::VersionedSchema',
    VERSION_FROM => 'lib/DBIx/VersionedSchema.pm', # finds $VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::TempDatabase' => '0.11',
		     'Class::Data::Inheritable' => '',
                    },
);
