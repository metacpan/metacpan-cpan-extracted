

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBIx::EnumConstraints',
    VERSION_FROM => 'lib/DBIx/EnumConstraints.pm', # finds \$VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Generates constraints for DB based enum',
    PREREQ_PM    => {
    			'Class::Accessor' => ''
			, 'Test::TempDatabase' => '0.13'
                    },
);
