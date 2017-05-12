#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

use App::SCM::Digest;
use App::SCM::Digest::Utils qw(system_ad system_ad_op);

use File::Temp qw(tempdir);

use lib './t/lib';
use TestFunctions qw(initialise_git_repository);

SKIP: {
    eval { App::SCM::Digest::SCM::Git->new(); };
    if ($@) {
        skip 'Git not available', 2;
    }

    my $repo_dir = tempdir(CLEANUP => 1);
    chdir $repo_dir;
    eval { initialise_git_repository() };
    if (my $error = $@) {
        skip 'Git not available', 2;
    }

    my $db_path   = tempdir(CLEANUP => 1);
    my $repo_path = tempdir(CLEANUP => 1);

    my %config = (
        db_path => $db_path,
        repository_path => $repo_path,
        headers => {
            from => 'Test User <test@example.org>',
            to   => 'Test User <test@example.org>',
        },
        repositories => [
            { name => 'test',
              url  => "file://$repo_dir",
              type => 'git' },
        ],
    );

    my $digest = eval { App::SCM::Digest->new(\%config); };
    ok($digest, 'Got new digest object');
    diag $@ if $@;

    eval { $digest->update(); };
    ok((not $@), 'Empty repository is ignored');
    diag $@ if $@;

    chdir('/tmp');
}

1;
