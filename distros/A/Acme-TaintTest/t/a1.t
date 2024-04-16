#!/usr/bin/perl -T

# test with arbitrary tainted string of absolute path of a real directory

use File::Spec;
use File::Temp qw(tempdir);

use Test::More tests => 1;

my $pathdir = $ENV{HOME};  # make variable tainted and set to an existing absolute directory 
(-d $pathdir) and File::Spec->file_name_is_absolute($pathdir);

my $workdir = tempdir("temp.XXXXXX", DIR => "log");

ok((-d $workdir), 'tempdir test');
