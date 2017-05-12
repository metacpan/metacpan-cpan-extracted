use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Data::Lazy',
    'VERSION_FROM' => 'Lazy.pm', # finds $VERSION
   ($] ge '5.005')
    ? (
     'AUTHOR' => 'Jan Krynicky (Jenda@Krynicky.cz)',
     'ABSTRACT' => 'Provides "lazy" scalars, arrays and hashes.',
    )
    : (),
);
