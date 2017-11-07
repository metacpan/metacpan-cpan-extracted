#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 10;

use App::SCM::Digest;
use App::SCM::Digest::Utils qw(system_ad system_ad_op);

use File::Temp qw(tempdir);

use lib './t/lib';
use TestFunctions qw(initialise_bare_git_repository);

SKIP: {
    eval { App::SCM::Digest::SCM::Git->new(); };
    if ($@) {
        skip 'Git not available', 10;
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

    my $email;
    eval {
        $digest->update();
        $email = $digest->get_email();
    };
    ok((not $@), 'Updated database and attempted to generate email');
    diag $@ if $@;
    ok($email, 'Email generated for initial commit');
    my $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf1/m,
        'Email contains content from initial commit');

    chdir $repo_checkout_dir1;
    chdir $basename;
    system_ad_op("echo 'asdf2' > out2");
    system_ad("git add out2");
    system_ad("git commit -m 'out2'");
    system_ad_op("echo 'asdf3' > out3");
    system_ad("git add out3");
    system_ad("git commit -m 'out3'");
    system_ad("git push");

    eval {
        $digest->update();
        $email = $digest->get_email();
    };
    ok((not $@), 'Updated database and attempted to generate email');
    diag $@ if $@;
    ok($email, 'Email generated for next commits');
    $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf2.*asdf3/s,
        'Email contains content from next commits');

    my $repo_checkout_dir2 = tempdir(CLEANUP => 1);
    chdir $repo_checkout_dir2;

    system_ad("git clone $repo_dir");
    chdir $basename;
    system_ad("git reset --hard HEAD~2");
    system_ad_op("echo 'different' > out3");
    system_ad("git add out3");
    system_ad("git commit -m 'out3 new'");
    system_ad("git push --force");

    eval {
        $digest->update();
        $email = $digest->get_email();
    };
    ok((not $@), 'Merged conflicting changes, preferring remote');
    diag $@ if $@;
    ok($email, 'Email generated for initial commit');
    $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf1.*asdf2.*asdf3.*different/s,
        'Email contains content from all commits');

    chdir('/tmp');
}

1;
