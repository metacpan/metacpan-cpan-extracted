use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::AnyDBD',
    'VERSION_FROM' => 'AnyDBD.pm', # finds $VERSION
);
