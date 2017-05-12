use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Astro::MoonPhase',
    'VERSION_FROM' => 'MoonPhase.pm', # finds $VERSION
    'ABSTRACT_FROM'=> 'MoonPhase.pm',
    'LICENSE'      => 'unrestricted',
);
