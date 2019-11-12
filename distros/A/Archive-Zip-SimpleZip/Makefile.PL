#! perl -w

use strict ;
require 5.006 ;

use lib '.';
use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

my $ParentVersion = 2.090 ;

WriteMakefile( 
    NAME         => 'Archive::Zip::SimpleZip',
    VERSION_FROM => 'lib/Archive/Zip/SimpleZip.pm',
    'dist'       => { COMPRESS     => 'gzip', 
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },
      
    ( $] >= 5.005
        ? (ABSTRACT => 'Read and Write Zip Archives',
            AUTHOR  => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

    ( (ExtUtils::MakeMaker->VERSION() gt '6.30') 
        ? ('LICENSE'  => 'perl')         
        : ()
    ), 

     ( eval { ExtUtils::MakeMaker->VERSION(6.46) }  
        ? ( META_MERGE  => {
    
                "meta-spec" => { version => 2 },

                no_index => {
                    directory => [ 't', 'private' ],
                },

                resources   => {
                
                    bugtracker  => {
                        web     => 'https://github.com/pmqs/Archive-Zip-SimpleZip/issues'
                    },

                    homepage    => 'https://github.com/pmqs/Archive-Zip-SimpleZip',

                    repository  => {
                        type    => 'git',
                        url     => 'git://github.com/pmqs/Archive-Zip-SimpleZip.git',
                        web     => 'https://github.com/pmqs/Archive-Zip-SimpleZip',
                    },        
                },

                prereqs => {
                    runtime => {
                        requires => {
                            'IO::Compress::Base'   => $ParentVersion,
                            'IO::Uncompress::Base' => $ParentVersion,
                            'Perl::OSType'         => 0,
                        },
                        recommends => {
                            'IO::Compress::Lzma'     => $ParentVersion,
                            'IO::Uncompress::UnLzma' => $ParentVersion,
                        },
                    },
                },
              } 
            ) 
        : ( PREREQ_PM   => { 
                'IO::Compress::Base'   => $ParentVersion,
                'IO::Uncompress::Base' => $ParentVersion,
                'Perl::OSType'         => 0,
                } 
          )
    ),

   

) ;

# end of file Makefile.PL

