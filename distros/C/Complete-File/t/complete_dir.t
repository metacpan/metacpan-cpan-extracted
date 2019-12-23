#!perl

use 5.010;
use strict;
use warnings;

use File::chdir;
use File::Temp qw(tempdir);
use Test::More;

use Complete::File qw(complete_dir);

sub mkfiles { do { open my($fh), ">$_" or die "Can't mkfile $_" } for @_ }
sub mkdirs  { do { mkdir $_ or die "Can't mkdir $_" } for @_ }

my $rootdir = tempdir(CLEANUP=>1);
$CWD = $rootdir;
mkfiles(qw(a ab abc ac bb d .h1));
mkdirs (qw(dir1 dir2 foo));
#mkdirs (qw(dir1/sub1 dir2/sub2 dir2/sub3));
#mkfiles(qw(foo/f1 foo/f2 foo/g));

test_complete(
    word      => '',
    result    => {path_sep=>'/', words=>[qw(dir1/ dir2/ foo/)]},
);

DONE_TESTING:
$CWD = "/";
done_testing;

sub test_complete {
    my (%args) = @_;

    my $name = $args{name} // $args{word};
    my $res = complete_dir(
        word=>$args{word}, array=>$args{array},
        ci=>$args{ci} // 0,
        map_case=>$args{map_case} // 0,
        exp_im_path=>$args{exp_im_path} // 0,
        @{ $args{other_args} // [] });
    is_deeply($res, $args{result}, "$name (result)") or diag explain($res);
}
