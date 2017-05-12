#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use C::Utility 'hash_to_c_file';
use File::Slurper 'read_text';
my $file = "$Bin/my.c";
my $hfile = hash_to_c_file ($file, { version => '0.01', author => 'Michael Caine' });
print "C file:\n\n";
print read_text ($file);
print "\nHeader file:\n\n";
print read_text ($hfile);
unlink $file, $hfile or die $!;
