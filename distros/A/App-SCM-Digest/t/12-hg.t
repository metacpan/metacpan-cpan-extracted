#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 14;

use App::SCM::Digest::SCM::Hg;
use App::SCM::Digest::Utils qw(system_ad system_ad_op);

use File::Temp qw(tempdir);

SKIP: {
    my $hg = eval { App::SCM::Digest::SCM::Hg->new(); };
    if ($@) {
        skip 'Mercurial not available', 14;
    }

    eval { $hg->clone('invalid', 'invalid') };
    ok($@, 'Died trying to clone invalid URL');
    like($@, qr/Command.*failed/, 'Got expected error message');

    my $repo_dir = tempdir(CLEANUP => 1);
    chdir $repo_dir;
    system_ad("hg init .");

    $hg->open_repository($repo_dir);
    my @branches = @{$hg->branches()};
    is_deeply(\@branches, [],
              'No branches found in repository');

    system_ad("hg branch new-branch");
    system_ad_op("echo 'asdf' > out");
    system_ad("hg add out");
    system_ad("hg commit -u out -m 'out'");

    my $repo_holder = tempdir(CLEANUP => 1);
    chdir $repo_holder;
    my $hg2 = App::SCM::Digest::SCM::Hg->new();
    $hg2->clone("file://".$repo_dir, "repo");
    $hg2->open_repository("repo");

    @branches = @{$hg2->branches()};
    my @branch_names = map { $_->[0] } @branches;
    is_deeply(\@branch_names, [qw(new-branch)],
              'New branch found in repository');

    is($hg2->branch_name(), 'new-branch',
        'Current branch name is correct');

    system_ad("hg branch new-branch2");
    system_ad_op("echo 'asdf2' > out2");
    system_ad("hg add out2");
    system_ad("hg commit -u out2 -m 'out2'");

    is($hg2->branch_name(), 'new-branch2',
        'Current branch name is correct (switched)');

    $hg2->checkout('new-branch');

    is($hg2->branch_name(), 'new-branch',
        'Current branch name is correct (switched back)');

    @branches = sort { $a->[0] cmp $b->[0] } @{$hg2->branches()};
    is_deeply($hg2->commits_from($branches[0]->[0], $branches[0]->[1]),
              [],
              'No commits found since most recent commit');

    system_ad_op("echo 'asdf3' > out3");
    system_ad("hg add out3");
    system_ad("hg commit -u out3 -m 'out3'");

    my @commits = @{$hg2->commits_from($branches[0]->[0], $branches[0]->[1])};
    is(@commits, 1, 'Found one commit since original commit');
    @branches = sort { $a->[0] cmp $b->[0] } @{$hg2->branches()};
    is($commits[0], $branches[0]->[1],
        'The found commit has the correct ID');

    ok($hg2->has($commits[0]), 'Has a commit');
    ok((not $hg2->has('invalid')), 'Does not have a commit');

    my $info = join '', @{$hg2->show($commits[0])};
    like($info, qr/out3/,
        'Log information contains log message');

    $info = join '', @{$hg2->show_all($commits[0])};
    like($info, qr/\+.*asdf3/,
        'Diff contains changed text');

    chdir("/tmp");
}

1;
