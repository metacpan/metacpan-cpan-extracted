#!perl

use strict;
use warnings;
use FindBin '$Bin';
use Test::More 0.98;

use File::Slurper qw(read_text);
use File::Temp qw(tempfile);
use IPC::System::Options 'system';

my ($tempfh, $tempfilename) = tempfile();
print $tempfh "line 1\nline 2\n";
close $tempfh;

system({shell=>1}, $^X, "-pe1", $tempfilename, \"|", $^X, "$Bin/../script/sponge", $tempfilename);
is(read_text($tempfilename), "line 1\nline 2\n");

system({shell=>1}, $^X, "-pe1", $tempfilename, \"|", $^X, "$Bin/../script/sponge", "-a", $tempfilename);
is(read_text($tempfilename), "line 1\nline 2\nline 1\nline 2\n");

done_testing;
