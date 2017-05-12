use Module::Build;

use feature qw( say );
use strict;
use warnings;

my ( $hts_include, $hts_lib ) = find_hts();

say STDERR "Header include dir is $hts_include, lib directory is $hts_lib";

my $build = Module::Build->new(
    module_name          => 'Bio::HTS',
    dist_version_from    => 'lib/Bio/HTS.pm',
    dist_author          => 'Alex Hodgkins',
    dist_abstract        => 'Perl interface to htslib. Currently only tabix is supported',
    create_readme        => 1,
    include_dirs         => [$hts_include],
    extra_linker_flags   => ["-L$hts_lib", '-lhts', '-lz'],
    extra_compiler_flags => [
        # must match DFLAGS in Samtools Makefile
        '-D_FILE_OFFSET_BITS=64', 
        # allow everything to work on files from the internet
        '-D_USE_KNETFILE',
    ],
    requires             => {
        'perl'          => '5.008',
        'Try::Tiny'     => '0.22',
        'Mouse'         => '2.4.2',
        'Log::Log4perl' => '1.46',
    },
    verbose              => 1,
    create_makefile_pl   => 'traditional',
);

$build->create_build_script;

sub find_hts {
    my $lib_file = "libhts.so";
    my $header_file = "htslib/tbx.h";

    my @search_path;

    #check LD_LIBRARY_PATH first to allow user to override /usr/local
    if ( defined $ENV{LD_LIBRARY_PATH} ) {
        push @search_path, split /:/, $ENV{LD_LIBRARY_PATH};
    }
    else {
        say "LD_LIBRARY_PATH is not set";
    }
    
    #could be in any of these places i guess
    push @search_path, qw( /usr/local /usr /usr/share );


    for my $folder ( @search_path ) {
        my ( $include_dir, $lib_dir );

        if ( -e "$folder/$header_file" ) {
            $include_dir = $folder;
        }
        elsif ( -e "$folder/include/$header_file" ) {
            $include_dir = "$folder/include/";
        }
        
        if ( -e "$folder/$lib_file" ) {
            $lib_dir = $folder;
        }
        elsif ( -e "$folder/lib/$lib_file" ) {
            $lib_dir = "$folder/lib/";
        }

        #we found what we expect so 
        if ( $lib_dir and $include_dir ) {
            return $include_dir, $lib_dir;
        }
    }

    die "Couldn't find $lib_file and $header_file in the following list of folders (did you set LD_LIBRARY_PATH?): " . join ", ", @search_path;
}
