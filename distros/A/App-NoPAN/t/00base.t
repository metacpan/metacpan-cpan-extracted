use strict;
use warnings;

use Cwd;
use File::Basename qw(basename);
use File::Slurp qw(read_file);
use File::Temp qw(tempdir);
use Test::More;

use_ok('App::NoPAN');

my $nopan = App::NoPAN->new();

my $url = "file://@{[getcwd]}/t.assets/rget/";

my @root_files = sort $nopan->files_from_dir($url);
is_deeply \@root_files, [ qw(a/ zzz.txt) ], 'files_from_dir';

my $tempdir = tempdir(CLEANUP => 1);
$nopan->fetch_all($url, $tempdir, '', \@root_files);
is read_file("t.assets/rget/$_"), read_file("$tempdir/$_"), "compare $_"
    for qw(zzz.txt a/b/hello.txt);

done_testing;
