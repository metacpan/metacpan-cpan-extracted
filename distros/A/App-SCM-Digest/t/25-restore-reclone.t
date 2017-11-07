#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

use App::SCM::Digest;
use App::SCM::Digest::Utils qw(system_ad system_ad_op);

use File::Temp qw(tempdir);

use lib './t/lib';
use TestFunctions qw(initialise_bare_git_repository);

SKIP: {
    eval { App::SCM::Digest::SCM::Git->new(); };
    if ($@) {
        skip 'Git not available', 4;
    }

    my $repo_dir = tempdir(CLEANUP => 1);
    my @parts = split /\//, $repo_dir;
    my $basename = $parts[$#parts];
    chdir $repo_dir;
    initialise_bare_git_repository();

    my $repo_checkout_dir1 = tempdir(CLEANUP => 1);
    chdir $repo_checkout_dir1;
    system_ad("git clone $repo_dir");
    chdir $basename;
    system_ad_op("echo 'asdf1' > out1");
    system_ad("git add out1");
    system_ad("git commit -m 'out1'");
    system_ad("git push -u origin master");

    sleep(1);

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
    ok((not $@), 'Updated database');
    diag $@ if $@;

    {
        no warnings;
        no strict 'refs';
        *{'App::SCM::Digest::_update_repository'} = sub {
            die "Overridden error";
        };
    }

    open my $fh, '>', $repo_path.'/test/out2';
    print $fh 'out2';
    close $fh;

    eval { $digest->update(); };
    ok($@, 'Failed to update database');

    ok((-e $repo_path.'/test/out2'),
        'Previous repository restored on failed post-reclone operation');

    chdir('/tmp');
}

1;
