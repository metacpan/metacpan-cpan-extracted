use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		    => 'Biblio-LCC',
    'AUTHOR'        => 'Paul Hoffman <nkuitse AT cpan DOT org>',
    'VERSION_FROM'	=> 'lib/Biblio/LCC.pm',
    'LICENSE'      => 'perl',
    'PREREQ_PM'     => {
                            'Test::More' => 0,
                            'Getopt::Long' => 0,
                            'File::Basename' => 0,
                       },
    'EXE_FILES'     => [ 'script/lccnorm' ],
);

