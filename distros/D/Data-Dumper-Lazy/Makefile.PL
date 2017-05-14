

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::Dumper::Lazy',
    VERSION_FROM => 'lib/Data/Dumper/Lazy.pm', # finds \$VERSION
    AUTHOR       => 'Rolf Michael Langsdorf (lanx@cpan.org)',
    ABSTRACT     => 'Reliably dump variables with names',
    PREREQ_PM    => {
	'Test::Simple' => 0.44,
	'Test::More'   => 0,
	'B::Deparse'   => 0,
    },
);
