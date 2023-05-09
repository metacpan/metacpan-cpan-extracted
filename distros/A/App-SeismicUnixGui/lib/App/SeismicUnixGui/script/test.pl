#!/bin/perl

use Moose;
use Cwd;
use File::Basename;
use File::Spec;
my $local = getcwd();

my $Fortran_pathNfile = $local;

my ( $filename, $Fortran_path ) = fileparse($Fortran_pathNfile);

print "Directory : " . $Fortran_path . "\n";
my @dirs = File::Spec->splitdir($Fortran_path);      # parse directories
pop @dirs;                                           # remove top dir
print ("@dirs \n");
my $SeismicUnixGui_path = File::Spec->catdir(@dirs);    # create new path
print(
"\nFor your system the environment variable: \$SeismicUnixGui appears to be:\n $SeismicUnixGui_path\n\n"
);



