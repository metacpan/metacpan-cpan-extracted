#!/usr/bin/env perl
use strict; use warnings;
use English;
use File::Basename;
use File::Spec;
my $dir = dirname(__FILE__);
my $libdir = File::Spec->catfile($dir, '..', 'lib');
# Something to make sure we are recursing subroutines.
sub five() {
    5
}
my $file;
if (scalar @ARGV) {
    $file = shift @ARGV;
    die "Can't find file $file" unless -f $file;
} else {
    $file = __FILE__;
}
open FH, '<', $file or die $!;
local $INPUT_RECORD_SEPARATOR; # enable localized slurp mode
my $content = <FH>;
open STDERR, '>', '/dev/null' or die $!;
my $rc = system ($EXECUTABLE_NAME, "-I$libdir", '-MO=CodeLines,-exec', '-e', 
		 $content);
unless (0 == $rc) {
    die "$file didn't parse\n";
}
