use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Bundle::perlWebSite',
    'VERSION_FROM' => 'perlWebSite.pm', # finds $VERSION
);
