#!perl

use 5.010;
use strict;
use warnings;

use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Filesys::Cap qw(fs_is_cs);
use Test::More 0.98;
use Complete::Program qw(complete_program);

sub mkexe { write_text($_[0], ""); chmod 0755, $_[0] }

local $Complete::Common::OPT_CI = 0;
local $Complete::Common::OPT_MAP_CASE = 0;
local $Complete::Common::OPT_FUZZY = 0;

my $dir = tempdir(CLEANUP=>1);
mkdir("$dir/dir1");
mkdir("$dir/dir2");
mkexe("$dir/dir1/prog1.bat");
mkexe("$dir/dir1/prog2.bat");
mkexe("$dir/dir2/prog3.bat");

subtest "unix/colon-separated PATH" => sub {
    local $^O = 'linux';
    plan skip_all => 'tempdir contains colon' if $dir =~ /:/;

    local $ENV{PATH} = "$dir/dir1:$dir/dir2";
    is_deeply(complete_program(word=>"prog"), ["prog1.bat","prog2.bat","prog3.bat"]);
    is_deeply(complete_program(word=>"prog3"), ["prog3.bat"]);
    is_deeply(complete_program(word=>"prog9"), []);
};

subtest "win/semicolon-separated PATH" => sub {
    local $^O = 'MSWin32';
    plan skip_all => 'tempdir contains semicolon' if $dir =~ /;/;

    local $ENV{PATH} = "$dir/dir1;$dir/dir2";
    is_deeply(complete_program(word=>"prog"), ["prog1.bat","prog2.bat","prog3.bat"]);
    is_deeply(complete_program(word=>"prog3"), ["prog3.bat"]);
    is_deeply(complete_program(word=>"prog9"), []);
};

done_testing;
