use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Acme::Turing',
    'VERSION_FROM' => 'Turing.pm', # finds $VERSION
);
