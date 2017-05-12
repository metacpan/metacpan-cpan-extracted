use inc::Module::Install;

WriteMakefile (
     NAME               => 'App-DualLivedList',
     ABSTRACT           => 'Determines if a module is Dual-Lived',
     LICENSE            => 'perl',
     VERSION            => '0.05',
     PREREQ_PM          => { 
                             'CPAN' => 0,
                             'Getopt::Long' => 0,
                             'Module::CoreList' => 0,
                             'Term::ANSIColor::Print' => 0
                           },
    
     EXE_FILES          => [qw(bin/dual-lived)],
                                                        
     dist               => {'COMPRESS' => 'gzip -9f', 
                            'SUFFIX'   => '.gz', },
    (
        $] >= 5.005     
            ? ( AUTHOR  => 'Kevin W. Henwood <Khen1950fx@aol.com>') 
            : ()
     ),
     (
            ExtUtils::MakeMaker->VERSION() gt '5.50' 
                ?  ( LICENSE  => 'Perl')         
                : ()
        ),

);  
