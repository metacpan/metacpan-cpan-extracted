use Test::More;
use Test::Exception;
use Test::TempDir qw( scratch );
use Test::Bot::BasicBot::Pluggable;

use File::Spec   qw();
use Git::Wrapper qw();

use Cwd            qw( getcwd   );
use File::Basename qw( basename );
use File::Path     qw( rmtree   );

my $bot = Test::Bot::BasicBot::Pluggable->new();

ok($bot->load('Gitbot'), "Loaded Gitbot module");

is(
    $bot->tell_private("!git garbage"),
    'Buh? Wha?',
    'Gives a semi-useless error response when given an unknown !git command'
);

is(
    $bot->tell_private("!git gitweb_url"),
    "gitweb_url is: 'http://localhost/'",
    'Gives the current git_gitweb_url, when not given a 2nd argument'
);

is(
    $bot->tell_private('!git gitweb_url http://example.com/'),
    "gitweb_url is now: 'http://example.com/'",
    'Notifies the user that the git_gitweb_url is now the 2nd argument'
);

is(
    $bot->tell_private('!git gitweb_url'),
    "gitweb_url is: 'http://example.com/'",
    'Gives the updated git_gitweb_url, when not given a 2nd argument'
);

like(
    $bot->tell_private("!git repo_root"),
    qr{repo_root is: '.*/repositories'},
    'Gives the current git_repo_root, when not given a 2nd argument'
);

is(
    $bot->tell_private('!git repo_root /gitbot/repos/live/here'),
    "repo_root is now: '/gitbot/repos/live/here'",
    'Notifies the user that the git_repo_root is now the 2nd argument'
);

is(
    $bot->tell_private('!git repo_root'),
    "repo_root is: '/gitbot/repos/live/here'",
    'Gives the updated git_repo_root, when not given a 2nd argument'
);

{
    my $path = File::Spec->rel2abs('foo');

    is(
        $bot->tell_private('!git repo_root foo'),
        "repo_root is now: '$path'",
        '"!git repo_root <path>" converts relative paths to abs paths'
    );
}

sub _abbreviate($) { substr shift, 0, 7 }

sub _make_git_repo_with_n_commits($$$)
{
    my ($repo_dir, $repo_name, $n_commits) = @_;
    $repo_dir->mkdir($repo_name);
    my $repo_path = File::Spec->rel2abs(File::Spec->catdir($repo_dir, $repo_name));

    my $git = Git::Wrapper->new($repo_path);
    $git->init();

    my @commit_shas;
    for (my $n = 1; $n <= $n_commits; $n++) {
        $repo_dir->touch(File::Spec->catfile($repo_name, 'file'), (qw|A few lines for the file.|)x$n);
        $git->add('.');

        local $ENV{GIT_AUTHOR_NAME}     = 'A. U. Thor';
        local $ENV{GIT_AUTHOR_EMAIL}    = 'a.u.thor@example.com';
        local $ENV{GIT_COMMITTER_NAME}  = 'Comm. I. Tor';
        local $ENV{GIT_COMMITTER_EMAIL} = 'comm.i.tor@example.com';

        $git->commit({message => "Commit number $n in $repo_name"});
        my ($commit) = $git->log({1 => 1});
        push @commit_shas, $commit->id();
    }

    return @commit_shas;
}

note 'Handles Git repos with working directories';
{
    my $repo_dir = scratch();
    my $repo_path = File::Spec->rel2abs("$repo_dir");

    is(
        $bot->tell_private("!git repo_root $repo_dir"),
        "repo_root is now: '$repo_path'",
        "Use the tempdir where we'll put our repositories"
    );

    is(
        $bot->tell_direct('help Gitbot'),
        "I don't know about any Git repositories.  I respond to the pattern /([0-9a-f]{7,})(?::(\\S+))?/i with a GitWeb URL.",
        'Check help text without any known repositories.'
    );

    my ($commit_sha, $second_sha, $third_sha) = _make_git_repo_with_n_commits($repo_dir, 'first_repo', 3);
    my $abbrev_sha        = _abbreviate($commit_sha);
    my $abbrev_second_sha = _abbreviate($second_sha);
    my $abbrev_third_sha  = _abbreviate($third_sha);

    is(
        $bot->tell_private("!git refresh_repos"),
        "I now know about 1 Git repository.",
        'Refresh the repository listing'
    );

    is(
        $bot->tell_indirect($commit_sha),
        "[first_repo $abbrev_sha] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=commitdiff;hb=$commit_sha",
        'Handles full SHA1'
    );

    is(
        $bot->tell_indirect("$commit_sha:file"),
        "[first_repo $abbrev_sha:file] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=blob;hb=$commit_sha;f=file [blob]",
        'Handles <sha>:<file> properly'
    );

    is(
        $bot->tell_indirect($abbrev_sha),
        "[first_repo $abbrev_sha] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=commitdiff;hb=$abbrev_sha",
        'Handles abbreviated SHA1'
    );

    is(
        $bot->tell_indirect("$abbrev_sha:file"),
        "[first_repo $abbrev_sha:file] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=blob;hb=$abbrev_sha;f=file [blob]",
        'Handles <abbreviated_sha>:<file> properly'
    );

    is(
        $bot->tell_indirect(substr $commit_sha, 0, 6),
        '',
        'Does not respond to SHA1s shorter than 7 characters.'
    );

    is(
        $bot->tell_indirect("1111111"),
        '',
        'Does not say anything when given a bad SHA1.'
    );

    is(
        $bot->tell_indirect('first_repo/master'),
        '[first_repo master] Commit number 3 in first_repo - http://example.com/?p=first_repo;a=log;hb=master',
        'Handles <repo>/<branch> properly.'
    );

    is(
        $bot->tell_indirect('first_repo/master:file'),
        '[first_repo master:file] Commit number 3 in first_repo - http://example.com/?p=first_repo;a=blob;hb=master;f=file [blob]',
        'Handles <repo>/<branch>:file properly'
    );

    is(
        $bot->tell_indirect('first_repo/refs/heads/master'),
        '[first_repo refs/heads/master] Commit number 3 in first_repo - http://example.com/?p=first_repo;a=log;hb=refs/heads/master',
        'Handles <repo>/<ref> properly.'
    );

    is(
        $bot->tell_indirect('first_repo/refs/heads/master:file'),
        '[first_repo refs/heads/master:file] Commit number 3 in first_repo - http://example.com/?p=first_repo;a=blob;hb=refs/heads/master;f=file [blob]',
        'Handles <repo>/<ref>:file properly'
    );

    is(
        $bot->tell_indirect('repo_does_not_exist/master'),
        '',
        'Does not say anything when asked for a repo that does not exist.'
    );

    is(
        $bot->tell_indirect('first_repo/branch-does-not-exist'),
        '',
        'Does not say anything when asked for a branch that does not exist.'
    );

    is(
        $bot->tell_indirect('first_repo/refs/nope/master'),
        '',
        'Does not say anything when asked for a ref that does not exist.'
    );

    is(
        $bot->tell_indirect("$commit_sha $second_sha $third_sha"),
        "[first_repo $abbrev_sha] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=commitdiff;hb=$commit_sha\n"
        . "[first_repo $abbrev_second_sha] Commit number 2 in first_repo - http://example.com/?p=first_repo;a=commitdiff;hb=$second_sha\n"
        . "[first_repo $abbrev_third_sha] Commit number 3 in first_repo - http://example.com/?p=first_repo;a=commitdiff;hb=$third_sha",
        'Handles multiple SHA matches in a single message.'
    );

    $repo_dir->cleanup();
}

note 'Handles bare Git repos';
{
    my $repo_dir = scratch();
    my $repo_path = File::Spec->rel2abs("$repo_dir");

    is(
        $bot->tell_private("!git repo_root $repo_dir"),
        "repo_root is now: '$repo_path'",
        "Use the tempdir where we'll put our repositories"
    );

    is(
        $bot->tell_direct('help Gitbot'),
        "I don't know about any Git repositories.  I respond to the pattern /([0-9a-f]{7,})(?::(\\S+))?/i with a GitWeb URL.",
        'Check help text without any known repositories.'
    );

    my ($commit_sha)    = _make_git_repo_with_n_commits($repo_dir, 'first_repo', 1);
    my $abbrev_sha      = _abbreviate($commit_sha);
    my $first_repo_path = File::Spec->catdir($repo_path, 'first_repo');

    system("git clone -q --no-hardlinks $first_repo_path $first_repo_path.git");
    rmtree($first_repo_path);

    is(
        $bot->tell_private("!git refresh_repos"),
        "I now know about 1 Git repository.",
        'Refresh the repository listing'
    );

    is(
        $bot->tell_indirect($commit_sha),
        "[first_repo.git $abbrev_sha] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=commitdiff;hb=$commit_sha",
        'Handles full SHA1'
    );

    is(
        $bot->tell_indirect("$commit_sha:file"),
        "[first_repo.git $abbrev_sha:file] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=blob;hb=$commit_sha;f=file [blob]",
        'Handles <sha>:<file> properly'
    );

    is(
        $bot->tell_indirect($abbrev_sha),
        "[first_repo.git $abbrev_sha] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=commitdiff;hb=$abbrev_sha",
        'Handles abbreviated SHA1'
    );

    is(
        $bot->tell_indirect("$abbrev_sha:file"),
        "[first_repo.git $abbrev_sha:file] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=blob;hb=$abbrev_sha;f=file [blob]",
        'Handles <abbreviated_sha>:<file> properly'
    );

    is(
        $bot->tell_indirect(substr $commit_sha, 0, 6),
        '',
        'Does not respond to SHA1s shorter than 7 characters.'
    );

    is(
        $bot->tell_indirect('first_repo/master'),
        '[first_repo.git master] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=log;hb=master',
        'Handles <repo>/<branch> properly.'
    );

    is(
        $bot->tell_indirect('first_repo/master:file'),
        '[first_repo.git master:file] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=blob;hb=master;f=file [blob]',
        'Handles <repo>/<branch>:file properly'
    );

    is(
        $bot->tell_indirect('first_repo/refs/heads/master'),
        '[first_repo.git refs/heads/master] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=log;hb=refs/heads/master',
        'Handles <repo>/<ref> properly.'
    );

    is(
        $bot->tell_indirect('first_repo/refs/heads/master:file'),
        '[first_repo.git refs/heads/master:file] Commit number 1 in first_repo - http://example.com/?p=first_repo.git;a=blob;hb=refs/heads/master;f=file [blob]',
        'Handles <repo>/<ref>:file properly'
    );

    $repo_dir->cleanup();
}

note 'Handles multiple repos';
{
    my $repo_dir = scratch();
    my $repo_path = File::Spec->rel2abs("$repo_dir");

    is(
        $bot->tell_private("!git repo_root $repo_dir"),
        "repo_root is now: '$repo_path'",
        "Use the tempdir where we'll put our repositories"
    );

    is(
        $bot->tell_direct('help Gitbot'),
        "I don't know about any Git repositories.  I respond to the pattern /([0-9a-f]{7,})(?::(\\S+))?/i with a GitWeb URL.",
        'Check help text without any known repositories.'
    );

    my ($first_repo_commit_sha)  = _make_git_repo_with_n_commits($repo_dir, 'first_repo',  1);
    my $first_repo_abbrev_sha    = _abbreviate($first_repo_commit_sha);
    my ($second_repo_commit_sha) = _make_git_repo_with_n_commits($repo_dir, 'second_repo', 1);
    my $second_repo_abbrev_sha   = _abbreviate($second_repo_commit_sha);
    my ($third_repo_commit_sha)  = _make_git_repo_with_n_commits($repo_dir, 'third_repo',  1);
    my $third_repo_abbrev_sha    = _abbreviate($third_repo_commit_sha);

    is(
        $bot->tell_private("!git refresh_repos"),
        "I now know about 3 Git repositories.",
        'Refresh the repository listing'
    );

    is(
        $bot->tell_indirect($first_repo_commit_sha),
        "[first_repo $first_repo_abbrev_sha] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=commitdiff;hb=$first_repo_commit_sha",
        'Finds the correct repository for a first_repo SHA1'
    );

    is(
        $bot->tell_indirect("$first_repo_commit_sha:file"),
        "[first_repo $first_repo_abbrev_sha:file] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=blob;hb=$first_repo_commit_sha;f=file [blob]",
        'Handles <sha>:<file> properly for first_repo'
    );

    is(
        $bot->tell_indirect($first_repo_abbrev_sha),
        "[first_repo $first_repo_abbrev_sha] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=commitdiff;hb=$first_repo_abbrev_sha",
        'Handles abbreviated SHA1 for first_repo'
    );

    is(
        $bot->tell_indirect("$first_repo_abbrev_sha:file"),
        "[first_repo $first_repo_abbrev_sha:file] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=blob;hb=$first_repo_abbrev_sha;f=file [blob]",
        'Handles <abbreviated_sha>:<file> properly for first_repo'
    );

    is(
        $bot->tell_indirect('first_repo/master'),
        '[first_repo master] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=log;hb=master',
        'Handles <repo>/<branch> properly.'
    );

    is(
        $bot->tell_indirect('first_repo/master:file'),
        '[first_repo master:file] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=blob;hb=master;f=file [blob]',
        'Handles <repo>/<branch>:file properly'
    );

    is(
        $bot->tell_indirect('first_repo/refs/heads/master'),
        '[first_repo refs/heads/master] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=log;hb=refs/heads/master',
        'Handles <repo>/<ref> properly.'
    );

    is(
        $bot->tell_indirect('first_repo/refs/heads/master:file'),
        '[first_repo refs/heads/master:file] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=blob;hb=refs/heads/master;f=file [blob]',
        'Handles <repo>/<ref>:file properly'
    );

    is(
        $bot->tell_indirect($second_repo_commit_sha),
        "[second_repo $second_repo_abbrev_sha] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=commitdiff;hb=$second_repo_commit_sha",
        'Finds the correct repository for a second_repo SHA1'
    );

    is(
        $bot->tell_indirect("$second_repo_commit_sha:another_file"),
        "[second_repo $second_repo_abbrev_sha:another_file] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=blob;hb=$second_repo_commit_sha;f=another_file [blob]",
        'Handles <sha>:<file> properly for second_repo'
    );

    is(
        $bot->tell_indirect($second_repo_abbrev_sha),
        "[second_repo $second_repo_abbrev_sha] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=commitdiff;hb=$second_repo_abbrev_sha",
        'Handles abbreviated SHA1 for second_repo'
    );

    is(
        $bot->tell_indirect("$second_repo_abbrev_sha:file"),
        "[second_repo $second_repo_abbrev_sha:file] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=blob;hb=$second_repo_abbrev_sha;f=file [blob]",
        'Handles <abbreviated_sha>:<file> properly for second_repo'
    );

    is(
        $bot->tell_indirect('second_repo/master'),
        '[second_repo master] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=log;hb=master',
        'Handles <repo>/<branch> properly.'
    );

    is(
        $bot->tell_indirect('second_repo/master:file'),
        '[second_repo master:file] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=blob;hb=master;f=file [blob]',
        'Handles <repo>/<branch>:file properly'
    );

    is(
        $bot->tell_indirect('second_repo/refs/heads/master'),
        '[second_repo refs/heads/master] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=log;hb=refs/heads/master',
        'Handles <repo>/<ref> properly.'
    );

    is(
        $bot->tell_indirect('second_repo/refs/heads/master:file'),
        '[second_repo refs/heads/master:file] Commit number 1 in second_repo - http://example.com/?p=second_repo;a=blob;hb=refs/heads/master;f=file [blob]',
        'Handles <repo>/<ref>:file properly'
    );

    is(
        $bot->tell_indirect("first_repo/master third_repo/master"),
        "[first_repo master] Commit number 1 in first_repo - http://example.com/?p=first_repo;a=log;hb=master\n"
        .  "[third_repo master] Commit number 1 in third_repo - http://example.com/?p=third_repo;a=log;hb=master",
        'Handles multiple <repo>/<branch> matches in a single message.'
    );

    $repo_dir->cleanup();
}

done_testing();
