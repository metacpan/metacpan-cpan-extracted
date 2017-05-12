#!perl
use strict;
use Config;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec::Functions;

print "Looking for lzma in path... ";
my $found = find('lzma');

if ($found) {
    print "found it at $found\n";
} else {
    print "didn't find it\n";
    warn "****************************************************************
Compress::LZMA::External could not find program 'lzma'. Please 
install it and try again. For Ubuntu: sudo apt-get install lzma 
****************************************************************\n";
    exit 0;
}

WriteMakefile(
    NAME         => 'Compress::LZMA::External',
    VERSION_FROM => 'lib/Compress/LZMA/External.pm',
    ABSTRACT     => 'Compress and decompress using LZMA',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => { 'Test::More' => '0', 'File::Temp' => '0.19', }
);

sub find {
    my $binary   = shift;
    my $path_sep = $Config{path_sep};
    my $exe_ext  = $Config{exe_ext};
    foreach my $dir ( split $path_sep, $ENV{PATH} ) {
        my $filename = catfile( $dir, $binary );
        return $filename if -x "$filename$exe_ext";
    }
    return 0;
}
