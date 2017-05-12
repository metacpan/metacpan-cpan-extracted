use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Astroboy',
   VERSION_FROM => 'lib/Astroboy.pm',
   

   # gen /usr/bin/pmused by Wed Mar 18 11:56:03 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'File::Path'                        => '1.08',
      'File::PathInfo'                    => '1.25',
      'File::Which'                       => '0.05',
      'Getopt::Std::Strict'               => '1.01',
      'LEOCHARRE::Class2'                 => '1.13',
      'LEOCHARRE::DEBUG'                  => '1.11',
      'LEOCHARRE::Dir'                    => '1.06',
      'MP3::Tag'                          => '0.9713',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [qw(bin/astroboy
		bin/astroboyfindbad
		bin/astroboyid3guess
		bin/astroboyinfo
		bin/m4amp3.pl
		bin/mp3resize)],
);


