#! /usr/bin/perl

# ARGV should be a .xs file
# What we're expecting is a line (or more) like this
# MODULE = TagLib         PACKAGE = TagLib::APE::Footer

use File::Slurp;

foreach $file ( @ARGV ) {
    @file = read_file( $file );
    map { s{MODULE = }{MODULE = Audio::} } @file;
    map { s{PACKAGE = }{PACKAGE = Audio::}; 0 } @file;
    write_file( $file, @file );
}

