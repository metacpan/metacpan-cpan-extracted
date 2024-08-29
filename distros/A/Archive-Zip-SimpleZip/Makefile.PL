#! perl -w

use strict ;
require 5.006 ;

use lib '.';
use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

my $ParentVersion = 2.213 ;

# Check if th eother IO::Compress::* modules are installed.
# If any are, add to PREREQ_PM.
my %extra_prereq = ();
$extra_prereq{'IO::Compress::Lzma'} = $ParentVersion
    if eval { require IO::Compress::Lzma; 1 } ;
$extra_prereq{'IO::Compress::Bzip2'} = $ParentVersion
    if eval { require IO::Compress::Bzip2; 1 } ;
$extra_prereq{'IO::Compress::Xz'} = $ParentVersion
    if eval { require IO::Compress::Xz; 1 } ;
$extra_prereq{'IO::Compress::Zstd'} = $ParentVersion
    if eval { require IO::Compress::Zstd; 1 } ;

WriteMakefile(
    NAME         => 'Archive::Zip::SimpleZip',
    VERSION_FROM => 'lib/Archive/Zip/SimpleZip.pm',
    'dist'       => { COMPRESS     => 'gzip',
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },


    PREREQ_PM   => {
            'IO::Compress::Base'   => $ParentVersion,
            'IO::Uncompress::Base' => $ParentVersion,
            'Perl::OSType'         => 0,
            %extra_prereq,
            } ,

    ( $] >= 5.005
        ? (ABSTRACT => 'Read and Write Zip Archives',
           AUTHOR   => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

    ( eval { ExtUtils::MakeMaker->VERSION(6.31) }
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
                            'IO::Compress::Base'        => $ParentVersion,
                            'IO::Uncompress::Base'      => $ParentVersion,
                            'IO::Compress::Zip'         => $ParentVersion,
                            'IO::Uncompress::Unzip'     => $ParentVersion,
                            'IO::Compress::RawDeflate'  => $ParentVersion,
                            'IO::Uncompress::RawInflate'=> $ParentVersion,
                            'Perl::OSType'              => 0,
                        },
                        recommends => {
                            'IO::Compress::Lzma'        => $ParentVersion,
                            'IO::Uncompress::UnLzma'    => $ParentVersion,
                            'IO::Compress::Zstd'        => $ParentVersion,
                            'IO::Uncompress::UnZstd'    => $ParentVersion,
                            'IO::Compress::Bzip2'       => $ParentVersion,
                            'IO::Uncompress::Bunzip2'   => $ParentVersion,
                            'IO::Compress::Xz'          => $ParentVersion,
                            'IO::Uncompress::UnXz'      => $ParentVersion,
                        },
                    },
                },
              }
            )
        : ()
    ),
) ;

# end of file Makefile.PL
