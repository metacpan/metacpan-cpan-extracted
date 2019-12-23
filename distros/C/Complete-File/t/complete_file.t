#!perl

use 5.010;
use strict;
use warnings;

use File::chdir;
use File::Temp qw(tempdir);
use Test::More;

use Complete::File qw(complete_file);

sub mkfiles { do { open my($fh), ">$_" or die "Can't mkfile $_" } for @_ }
sub mkdirs  { do { mkdir $_ or die "Can't mkdir $_" } for @_ }

local $Complete::Common::OPT_CI = 0;
local $Complete::Common::OPT_MAP_CASE = 0;
local $Complete::Common::OPT_EXP_IM_PATH = 0;
local $Complete::Common::OPT_FUZZY = 0;
local $Complete::Common::OPT_DIG_LEAF = 0;

my $rootdir = tempdir(CLEANUP=>1);
$CWD = $rootdir;
mkfiles(qw(a ab abc ac bb d .h1));
mkdirs (qw(dir1 dir2 foo));
mkdirs (qw(dir1/sub1 dir2/sub2 dir2/sub3));
mkfiles(qw(foo/f1 foo/f2 foo/g));

mkdirs (qw(Food));
mkdirs (qw(Food/Sub4));
mkfiles(qw(Food/f1 Food/F2));

mkfiles(qw(Food/Sub4/one Food/Sub4/one-two Food/Sub4/one_three));

mkdirs (qw(dir1/sub1/ext));
mkfiles(qw(dir1/sub1/ext/foo.bak));
mkfiles(qw(dir1/sub1/ext/foo.txt));
mkfiles(qw(dir1/sub1/ext/foo.tmp));

test_complete(
    word      => '',
    result    => {path_sep=>'/', words=>[qw(.h1 Food/ a ab abc ac bb d dir1/ dir2/ foo/)]},
);
test_complete(
    word      => 'a',
    result    => {path_sep=>'/', words=>[qw(a ab abc ac)]},
);
test_complete(
    name      => 'dir + file',
    word      => 'd',
    result    => {path_sep=>'/', words=>[qw(d dir1/ dir2/)]},
);
test_complete(
    name       => 'opt:filter (string, file only)',
    word       => 'd',
    other_args => [filter=>'-d'],
    result     => {path_sep=>'/', words=>[qw(d)]},
);
test_complete(
    name       => 'opt:filter (string, dir only, use |, not very meaningful test',
    word       => 'd',
    other_args => [filter=>'d|-f'],
    result     => {path_sep=>'/', words=>[qw(dir1/ dir2/)]},
);
test_complete(
    name       => 'opt:filter (code)',
    word       => '',
    other_args => [filter=>sub {my $res=(-d $_[0]) && $_[0] =~ m!\./f!}],
    result     => {path_sep=>'/', words=>[qw(foo/)]},
);
test_complete(
    name       => 'opt:exclude_dir',
    word       => 'd',
    other_args => [exclude_dir=>1],
    result     => {path_sep=>'/', words=>[qw(d)]},
);
test_complete(
    name       => 'opt:file_regex_filter',
    word       => '',
    other_args => [file_regex_filter=>qr/ab/],
    result     => {path_sep=>'/', words=>[qw(Food/ ab abc dir1/ dir2/ foo/)]},
);
test_complete(
    name       => 'opt:file_ext_filter (re)',
    word       => 'dir1/sub1/ext/',
    other_args => [file_ext_filter=>qr/^t/],
    result     => {path_sep=>'/', words=>[qw(dir1/sub1/ext/foo.tmp dir1/sub1/ext/foo.txt)]},
);
test_complete(
    name       => 'opt:file_ext_filter (array)',
    word       => 'dir1/sub1/ext/',
    other_args => [file_ext_filter=>[qw/txt tmp/]],
    result     => {path_sep=>'/', words=>[qw(dir1/sub1/ext/foo.tmp dir1/sub1/ext/foo.txt)]},
);

test_complete(
    name      => 'subdir 1',
    word      => 'foo/',
    result    => {path_sep=>'/', words=>["foo/f1", "foo/f2", "foo/g"]},
);
test_complete(
    name      => 'subdir 2',
    word      => 'foo/f',
    result    => {path_sep=>'/', words=>["foo/f1", "foo/f2"]},
);

# XXX test ../blah
# XXX test /abs
# XXX test ~/blah and ~user/blah

# XXX test opt:starting_path
# XXX test opt:allow_dot=0
# XXX test opt:handle_tilde=0

DONE_TESTING:
$CWD = "/";
done_testing;

sub test_complete {
    my (%args) = @_;

    my $name = $args{name} // $args{word};
    my $res = complete_file(
        word=>$args{word}, array=>$args{array},
        @{ $args{other_args} // [] });
    is_deeply($res, $args{result}, "$name (result)") or diag explain($res);
}
