#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 41;

use App::SCM::Digest;
use App::SCM::Digest::Utils qw(system_ad system_ad_op);

use File::Temp qw(tempdir);

use lib './t/lib';
use TestFunctions qw(initialise_git_repository);

SKIP: {
    eval { App::SCM::Digest::SCM::Git->new(); };
    if ($@) {
        skip 'Git not available', 41;
    }
    eval { App::SCM::Digest::SCM::Hg->new(); };
    if ($@) {
        skip 'Mercurial not available', 41;
    }

    my $repo_dir = tempdir(CLEANUP => 1);
    chdir $repo_dir;
    initialise_git_repository();
    system_ad_op("echo 'asdf' > outm");
    system_ad("git add outm");
    system_ad("git commit -m 'outm'");
    system_ad("git checkout -b new-branch");
    system_ad_op("echo 'asdf' > out");
    system_ad("git add out");
    system_ad("git commit -m 'out'");
    system_ad("git checkout -b new-branch2/test");
    system_ad_op("echo 'asdf2' > out2");
    system_ad("git add out2");
    system_ad("git commit -m 'out2'");

    my $other_remote_dir = tempdir(CLEANUP => 1);
    chdir $other_remote_dir;
    system_ad("git clone file://$repo_dir ord");
    my $other_remote_repo = "$other_remote_dir/ord";
    chdir $other_remote_repo;
    system_ad("git checkout -b new-branch4");
    system_ad_op("echo 'asdf4' > out4");
    system_ad("git add out4");
    system_ad("git commit -m 'out4'");

    my $hg_repo_dir = tempdir(CLEANUP => 1);
    chdir $hg_repo_dir;
    system_ad("hg init .");
    system_ad("hg branch new-branch");
    system_ad_op("echo 'qwer' > out");
    system_ad("hg add out");
    system_ad("hg commit -u out -m 'out'");
    system_ad("hg branch new-branch2/test");
    system_ad_op("echo 'qwer2' > out");
    system_ad("hg add out");
    system_ad("hg commit -u out -m 'out'");

    my $hg_other_remote_dir = tempdir(CLEANUP => 1);
    chdir $hg_other_remote_dir;
    system_ad("hg clone file://$hg_repo_dir ord");
    my $hg_other_remote_repo = "$hg_other_remote_dir/ord";
    chdir $hg_other_remote_repo;
    system_ad("hg branch new-branch4");
    system_ad_op("echo 'qwer4' > out4");
    system_ad("hg add out4");
    system_ad("hg commit -u out4 -m 'out4'");

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
            { name => 'test2',
              url  => "file://$hg_repo_dir",
              type => 'hg' },
        ],
    );

    my $digest = eval { App::SCM::Digest->new(\%config); };
    ok($digest, 'Got new digest object');
    diag $@ if $@;

    eval { $digest->get_email() };
    ok($@, 'Died trying to get email pre-initialisation');
    like($@, qr/Unable to open repository 'test'/,
        'Got correct error message');

    eval { $digest->_repository_map(\&App::SCM::Digest::_update_repository) };
    ok($@, 'Died trying to update pre-initialisation');
    like($@, qr/Unable to open repository 'test'/,
        'Got correct error message');

    my $email;
    eval {
        $digest->update();
        $email = $digest->get_email();
    };
    ok((not $@), 'Updated database and attempted to generate email');
    diag $@ if $@;
    ok($email, 'Email generated for initial commit');
    my $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf\s*$/m,
        'Email contains content from initial commit (git)');
    like($email_content, qr/qwer\s*$/m,
        'Email contains content from initial commit (hg)');

    eval {
        $digest->update();
        $email = $digest->get_email();
    };
    ok((not $@), 'Updated database and attempted to generate email (2)');
    diag $@ if $@;
    ok($email, 'Email generated for initial commit (2)');

    chdir $repo_dir;
    system_ad("git checkout new-branch");
    system_ad_op("echo 'asdf3' > out3");
    system_ad("git add out3");
    system_ad("git commit -m 'out3'");
    system_ad("git branch -D new-branch2/test");

    chdir $hg_repo_dir;
    system_ad("hg checkout new-branch");
    system_ad_op("echo 'qwer3' > out3");
    system_ad("hg add out3");
    system_ad("hg commit -u out3 -m 'out3'");

    eval {
        $digest->update();
        $email = $digest->get_email();
    };
    ok((not $@), 'Updated database and generated email');
    diag $@ if $@;
    ok($email, 'Email generated');

    $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf3\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/qwer3\s*$/m,
        'Email contains changed content (hg)');

    sleep(1);
    my $from = POSIX::strftime('%FT%T', gmtime(time()));
    $email = undef;
    chdir $other_remote_repo;
    system_ad("git push -u origin new-branch4");
    chdir $hg_other_remote_repo;
    system_ad("hg push -f");

    eval {
        $digest->update();
        $email = $digest->get_email($from);
    };
    ok((not $@), "Updated database and generated email ('from' provided)");
    diag $@ if $@;
    ok($email, 'Email generated');

    $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf4\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/qwer4\s*$/m,
        'Email contains changed content (hg)');
    unlike($email_content, qr/asdf3\s*$/m,
        'Email does not contain previous changed content (git)');
    unlike($email_content, qr/qwer3\s*$/m,
        'Email does not contain previous changed content (hg)');

    $email = undef;
    eval {
        $email = $digest->get_email('0000-01-01T00:00:00');
    };
    ok((not $@), "Generated email for all commits (zero 'from' provided)");
    diag $@ if $@;
    ok($email, 'Email generated');

    $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf3\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/qwer3\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/asdf\s*$/m,
        'Email contains initialisation content (git)');
    like($email_content, qr/qwer\s*$/m,
        'Email contains initialisation content (hg)');

    $email = undef;
    eval {
        $email = $digest->get_email(undef, '9999-01-01T00:00:00');
    };
    ok((not $@), 'Generated email for all commits (to provided)');
    diag $@ if $@;
    ok($email, 'Email generated');

    $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf3\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/qwer3\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/asdf\s*$/m,
        'Email contains initialisation content (git)');
    like($email_content, qr/qwer\s*$/m,
        'Email contains initialisation content (hg)');

    $email = undef;
    eval {
        $email =
            $digest->get_email('0000-01-01T00:00:00', '9999-01-01T00:00:00')
    };
    ok((not $@), 'Generated email for all commits (both provided)');
    diag $@ if $@;
    ok($email, 'Email generated');

    $email_content = join "\n", map { $_->body_str() } $email->parts();
    like($email_content, qr/asdf3\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/qwer3\s*$/m,
        'Email contains changed content (git)');
    like($email_content, qr/asdf\s*$/m,
        'Email contains initialisation content (git)');
    like($email_content, qr/qwer\s*$/m,
        'Email contains initialisation content (hg)');

    open my $fh, '>', $db_path."/test/new-branch4" or die $!;
    print $fh "";
    close $fh;

    eval {
        $digest->update();
        $digest->get_email();
    };
    ok($@, 'Unable to process when database corrupt');
    like($@, qr/Unable to find commit ID in database/,
        'Got correct error message');

    chdir('/tmp');
}

1;
