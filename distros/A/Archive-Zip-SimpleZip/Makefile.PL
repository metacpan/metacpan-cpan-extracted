#! perl -w

use strict ;
require 5.006 ;

use lib '.';
use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

WriteMakefile( 
    NAME         => 'Archive::Zip::SimpleZip',
    VERSION_FROM => 'lib/Archive/Zip/SimpleZip.pm',
    'dist'       => { COMPRESS     => 'gzip', 
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? ()
	    : (PREREQ_PM   => { 'IO::Compress::Base' => 2.081,
                             'Perl::OSType'      => 0,
                          }
	      )
    ),
       
    (
    $] >= 5.005
        ? (ABSTRACT => 'Create and Read Zip Archives',
            AUTHOR  => 'Paul Marquess <pmqs@cpan.org>')
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
              } 
            ) 
        : ()
    ),

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),    

) ;

# end of file Makefile.PL

