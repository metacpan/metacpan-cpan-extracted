#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 14;

use App::SCM::Digest::SCM::Git;
use App::SCM::Digest::Utils qw(system_ad system_ad_op);

use File::Temp qw(tempdir);

use lib './t/lib';
use TestFunctions qw(initialise_git_repository initialise_git_clone);

SKIP: {
    my $git = eval { App::SCM::Digest::SCM::Git->new(); };
    if ($@) {
        skip 'Git not available', 14;
    }

    eval { $git->clone('invalid url', 'invalid') };
    ok($@, 'Died trying to clone invalid URL');
    like($@, qr/Command.*failed/, 'Got expected error message');

    my $repo_dir = tempdir(CLEANUP => 1);
    chdir $repo_dir;
    eval { initialise_git_repository() };
    if (my $error = $@) {
        skip 'Git not available', 12;
    }

    $git->open_repository($repo_dir);
    my @branches = @{$git->branches()};
    is_deeply(\@branches, [],
              'No branches found in repository');

    system_ad_op("echo 'asdf' > outm");
    system_ad("git add outm");
    system_ad("git commit -m 'outm'");
    system_ad("git checkout -b new-branch");
    system_ad_op("echo 'asdf' > out");
    system_ad("git add out");
    system_ad("git commit -m 'out'");

    my $repo_holder = tempdir(CLEANUP => 1);
    chdir $repo_holder;
    my $git2 = App::SCM::Digest::SCM::Git->new();
    $git2->clone("file://".$repo_dir, "repo");
    $git2->open_repository("repo");
    initialise_git_clone();

    @branches = @{$git2->branches()};
    my @branch_names = map { $_->[0] } @branches;
    is_deeply(\@branch_names, [qw(master new-branch)],
              'New branch found in repository');

    is($git2->branch_name(), 'new-branch',
        'Current branch name is correct');

    system_ad("git checkout -b new-branch2");
    system_ad_op("echo 'asdf2' > out2");
    system_ad("git add out2");
    system_ad("git commit -m 'out2'");

    is($git2->branch_name(), 'new-branch2',
        'Current branch name is correct (switched)');

    $git2->checkout('new-branch');

    is($git2->branch_name(), 'new-branch',
        'Current branch name is correct (switched back)');

    @branches = sort { $a->[0] cmp $b->[0] } @{$git2->branches()};
    is_deeply($git2->commits_from($branches[0]->[0], $branches[0]->[1]),
              [],
              'No commits found since most recent commit');

    system_ad_op("echo 'asdf3' > out3");
    system_ad("git add out3");
    system_ad("git commit -m 'out3'");

    my ($branch, $id) = @{$branches[0]};
    my @commits = @{$git2->commits_from($branch, $id)};
    is(@commits, 1, 'Found one commit since original commit');
    @branches = sort { $a->[0] cmp $b->[0] } @{$git2->branches()};
    is($commits[0], $branches[0]->[1],
        'The found commit has the correct ID');

    system_ad_op("echo 'asdf4' > out4");
    system_ad("git add out4");
    system_ad("git commit -m 'out4'");

    @commits = @{$git2->commits_from($branch, $id)};
    is(@commits, 2, 'Found two commits since original commit');
    @branches = sort { $a->[0] cmp $b->[0] } @{$git2->branches()};
    is($commits[1], $branches[0]->[1],
        'The second commit has the correct ID');

    my $info = join '', @{$git2->show($commits[0])};
    like($info, qr/out3/,
        'Log information contains log message');

    $info = join '', @{$git2->show_all($commits[0])};
    like($info, qr/\+.*asdf3/,
        'Diff contains changed text');

    chdir("/tmp");
}

1;
