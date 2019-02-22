use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'C::Mlock',
    'VERSION_FROM' => 'Mlock.pm', # finds $VERSION
    'LIBS'	=> ['-lc'],
    'DEFINE'	=> '',
    'INC'	=> '',
    'OBJECT'    => 'Mlock.o store.o'
);
