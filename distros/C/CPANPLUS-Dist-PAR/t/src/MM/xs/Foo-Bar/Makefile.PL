use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Foo::Bar',
    'VERSION_FROM'  => 'Bar.pm', # finds $VERSION
    EXE_FILES       => ['bin/foobar.pl'],        
);
