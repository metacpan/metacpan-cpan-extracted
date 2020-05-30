#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use File::chdir;
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use App::UniqFiles qw(uniq_files);

my $dir = tempdir(CLEANUP => 1);
$CWD = $dir;

write_text("f1", "a");  # dupe c=3
write_text("f2", "a");  # dupe c=3
write_text("f3", "c");  # uniq
write_text("f4", "aa"); # uniq unless -R
write_text("f5", "a");  # dupe c=3
mkdir "subdir1";
write_text("subdir1/f6", "aa"); # dupe under -R, c=2
write_text("subdir1/f7", "ab"); # uniq
my @f = glob "*";

my $res;

subtest basics => sub {
    $res = uniq_files(files => \@f);
    is_deeply($res->[2], ["f1", "f3", "f4"]) or diag explain $res;
};

subtest "opt:report_duplicate=1" => sub {
    $res = uniq_files(files => \@f, report_duplicate=>1);
    is_deeply($res->[2], ["f1", "f2", "f3", "f4", "f5"]) or diag explain $res;
};

subtest "opt:report_unique=1, report_duplicate=1" => sub {
    $res = uniq_files(files => \@f, report_duplicate=>1);
    is_deeply($res->[2], ["f1", "f2", "f3", "f4", "f5"]) or diag explain $res;
};

subtest "opt:report_unique=0, report_duplicate=2 (-d)" => sub {
    $res = uniq_files(files => \@f, report_unique=>0, report_duplicate=>2);
    is_deeply($res->[2], ["f1"]) or diag explain $res;
};

subtest "opt:report_unique=0, report_duplicate=3 (-D)" => sub {
    $res = uniq_files(files => \@f, report_unique=>0, report_duplicate=>3);
    is_deeply($res->[2], ["f2", "f5"]) or diag explain $res;
};

subtest "opt:count=1 (-c)" => sub {
    $res = uniq_files(files => \@f, report_duplicate=>1, count=>1);
    is_deeply($res->[2], [{file=>"f1",count=>3}, {file=>"f2",count=>3}, {file=>"f3",count=>1}, {file=>"f4",count=>1}, {file=>"f5",count=>3}]) or diag explain $res;
};

subtest "opt:algorithm=none, recurse=1, show_size=1" => sub {
    $res = uniq_files(files => \@f, recurse=>1, algorithm=>"none", report_unique=>1, show_size=>1);
    is_deeply($res->[2], [{file=>"f1",size=>1}, {file=>"f4",size=>2}]) or diag explain $res;
};

subtest "opt:show_digest=1, group_by_digest=1" => sub {
    $res = uniq_files(files => \@f, recurse=>1, report_unique=>1, report_duplicate=>1, show_digest=>1, group_by_digest=>1);
    is_deeply($res->[2], [
        {file=>"f1",digest=>"0cc175b9c0f1b6a831c399e269772661"},
        {file=>"f2",digest=>"0cc175b9c0f1b6a831c399e269772661"},
        {file=>"f5",digest=>"0cc175b9c0f1b6a831c399e269772661"},
        {},
        {file=>"f3",digest=>"4a8a08f09d37b73795649038408b5f33"},
        {},
        {file=>"subdir1/f7",digest=>"187ef4436122d1cc2f40dc2b92f0eba0"},
        {},
        {file=>"f4",digest=>"4124bc0a9335c27f086f24ba207a4912"},
        {file=>"subdir1/f6",digest=>"4124bc0a9335c27f086f24ba207a4912"},
    ]) or diag explain $res;
};

subtest "opt:algorithm=sha1" => sub {
    $res = uniq_files(files => \@f, recurse=>1, algorithm=>"sha1", report_duplicate=>0, show_digest=>1);
    is_deeply($res->[2], [{file=>"f3",digest=>"84a516841ba77a5b4648de2cd0dfcb30ea46dbb4"}, {file=>"subdir1/f7",digest=>"da23614e02469a0d7c7bd1bdab5c9c474b1904dc"}]) or diag explain $res;
};

# XXX test opt:digest_args

done_testing;
