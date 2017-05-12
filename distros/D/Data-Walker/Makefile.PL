use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Data',
    'DISTNAME'	=> 'Walker',
    'VERSION_FROM' => 'Data/Walker.pm', # finds $VERSION
);
