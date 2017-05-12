use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Foo::Bar',
    VERSION_FROM    => 'lib/Foo/Bar.pm',
    EXE_FILES       => ['bin/foobar.pl'],    
);     
