# verifies that at least one test file has been modified
# (the goal being that one test has been added or altered)

use 5.38.0;

use Test2::V0;

use Git::Wrapper;

my $target_branch = $ENV{TARGET_BRANCH} // 'main';

my $git = Git::Wrapper->new('.');

my $on_target = grep { "* $target_branch" eq $_ } $git->branch;

skip_all "already on target branch" if $on_target;

skip_all "manually disabled" if $ENV{NO_NEW_TEST};

ok test_file_modified( $git->diff($target_branch) ), "added to a test file";

sub test_file_modified (@diff) {
    my $in_test_file = 0;
    for (@diff) {
        if (/^diff/) {
            $in_test_file = /\.t$/;
            next;
        }

        return 1 if $in_test_file and /^\+/;
    }

    return 0;
}

done_testing;
