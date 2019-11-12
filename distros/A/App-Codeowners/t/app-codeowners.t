#!/usr/bin/env perl

use warnings;
use strict;

use FindBin '$Bin';
use Test::Exit;     # must be first
use App::Codeowners::Util qw(run_git);
use App::Codeowners;
use Capture::Tiny qw(capture);
use File::pushd;
use Path::Tiny qw(path tempdir);
use Test::More;

my $can_git = _can_git();
plan skip_all => 'Cannot run git' if !$can_git;

# Set progname so that pod2usage knows how to find the script after we chdir
$0 = path($Bin)->parent->child('bin/git-codeowners')->absolute;

$ENV{NO_COLOR} = 1;

subtest 'basic options' => sub {
    my $repodir = _setup_git_repo();
    my $chdir   = pushd($repodir);

    my ($stdout, $stderr, $exit) = capture { exit_code { App::Codeowners->main('--help') } };
    is($exit, 0, 'exited 0 when --help');
    like($stdout, qr/Usage:/, 'correct --help output') or diag $stdout;

    ($stdout, $stderr, $exit) = capture { exit_code { App::Codeowners->main('--version') } };
    is($exit, 0, 'exited 0 when --version');
    like($stdout, qr/git-codeowners [\d.]+\n/, 'correct --version output') or diag $stdout;
};

subtest 'bad options' => sub {
    my $repodir = _setup_git_repo();
    my $chdir   = pushd($repodir);

    my ($stdout, $stderr, $exit) = capture { exit_code { App::Codeowners->main(qw{show --not-an-option}) } };
    is($exit, 2, 'exited with error on bad option');
    like($stderr, qr/Unknown option: not-an-option/, 'correct error message') or diag $stderr;
};

subtest 'show' => sub {
    my $repodir = _setup_git_repo();
    my $chdir   = pushd($repodir);

    my ($stdout, $stderr, $exit) = capture { exit_code { App::Codeowners->main(qw{-f %F;%O show}) } };
    is($exit, 0, 'exited without error');
    is($stdout, <<'END', 'correct output');
CODEOWNERS;
a/b/c/bar.txt;@snickers
foo.txt;@twix
END

    ($stdout, $stderr, $exit) = capture { exit_code { App::Codeowners->main(qw{-f %F;%O;%P show}) } };
    is($exit, 0, 'exited without error');
    is($stdout, <<'END', 'correct output');
CODEOWNERS;;
a/b/c/bar.txt;@snickers;peanuts
foo.txt;@twix;
END

    subtest 'format json' => sub {
        plan skip_all => 'No JSON::MaybeXS' if !eval { require JSON::MaybeXS };

        ($stdout, $stderr, $exit) = capture { exit_code { App::Codeowners->main(qw{-f json show --no-project}) } };
        is($exit, 0, 'exited without error');
        my $expect = '[{"File":"CODEOWNERS","Owner":null},{"File":"a/b/c/bar.txt","Owner":["@snickers"]},{"File":"foo.txt","Owner":["@twix"]}]';
        is($stdout, $expect, 'correct output with json format');
    };
};

done_testing;
exit;

sub _can_git {
    my ($version) = run_git('--version');
    return $version;
}

sub _setup_git_repo {
    my $repodir = tempdir;

    $repodir->child('foo.txt')->touchpath;
    $repodir->child('a/b/c/bar.txt')->touchpath;
    $repodir->child('CODEOWNERS')->spew_utf8([<<'END']);
# whatever
/foo.txt  @twix
# Project: peanuts
a/  @snickers
END

    run_git('-C', $repodir, qw{init});
    run_git('-C', $repodir, qw{add .});
    run_git('-C', $repodir, qw{commit -m}, 'initial commit');

    return $repodir;
}
