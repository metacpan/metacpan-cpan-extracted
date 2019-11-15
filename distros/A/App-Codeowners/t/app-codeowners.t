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

# Set progname so that pod2usage knows how to find the script after we chdir.
$0 = path($Bin)->parent->child('bin/git-codeowners')->absolute->stringify;

$ENV{NO_COLOR} = 1;

sub run(&) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $code = shift;
    capture { exit_code { $code->() } };
}

subtest 'basic options' => sub {
    my ($stdout, $stderr, $exit) = run { App::Codeowners->main('--help') };
    is($exit, 0, 'exited 0 when --help');
    like($stdout, qr/Usage:/, 'correct --help output') or diag $stdout;

    ($stdout, $stderr, $exit) = run { App::Codeowners->main('--version') };
    is($exit, 0, 'exited 0 when --version');
    like($stdout, qr/git-codeowners [\d.]+\n/, 'correct --version output') or diag $stdout;
};

subtest 'bad options' => sub {
    my ($stdout, $stderr, $exit) = run { App::Codeowners->main(qw{show --not-an-option}) };
    is($exit, 2, 'exited with error on bad option');
    like($stderr, qr/Unknown option: not-an-option/, 'correct error message') or diag $stderr;
};

subtest 'show' => sub {
    plan skip_all => 'Cannot run git' if !$can_git;

    my $repodir = _setup_git_repo();
    my $chdir   = pushd($repodir);

    my ($stdout, $stderr, $exit) = run { App::Codeowners->main(qw{-f %F;%O show}) };
    is($exit, 0, 'exited without error');
    is($stdout, <<'END', 'correct output');
CODEOWNERS;
a/b/c/bar.txt;@snickers
foo.txt;@twix
END

    ($stdout, $stderr, $exit) = run { App::Codeowners->main(qw{-f %F;%O;%P show}) };
    is($exit, 0, 'exited without error');
    is($stdout, <<'END', 'correct output');
CODEOWNERS;;
a/b/c/bar.txt;@snickers;peanuts
foo.txt;@twix;
END

    subtest 'format json' => sub {
        plan skip_all => 'No JSON::MaybeXS' if !eval { require JSON::MaybeXS };

        ($stdout, $stderr, $exit) = run { App::Codeowners->main(qw{-f json show --no-projects}) };
        is($exit, 0, 'exited without error');
        my $expect = '[{"File":"CODEOWNERS","Owner":null},{"File":"a/b/c/bar.txt","Owner":["@snickers"]},{"File":"foo.txt","Owner":["@twix"]}]';
        is($stdout, $expect, 'correct output with json format');
    };
};

subtest 'create' => sub {
    plan skip_all => 'Cannot run git' if !$can_git;

    my $repodir = _setup_git_repo();
    my $chdir   = pushd($repodir);

    my $codeowners_filepath = path('CODEOWNERS');
    $codeowners_filepath->remove;

    my ($stdout, $stderr, $exit) = run { App::Codeowners->main(qw{create}) };
    is($exit, 0, 'exited without error');
    is($stderr, "Wrote CODEOWNERS\n", 'reportedly wrote a CODEOWNERS file');

    ok($codeowners_filepath->is_file, 'did write CODEOWNERS file');

    my $contents = $codeowners_filepath->slurp_utf8;
    like($contents, qr/^# This file shows mappings/, 'correct contents of file') or diag $contents;
};

done_testing;
exit;

sub _can_git {
    my (undef, $version) = eval { run_git('--version') };
    note $@ if $@;
    note "Found: $version" if $version;
    return $version && $version ge 'git version 1.8.5';     # for -C flag
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

    run_git('-C', $repodir, qw{init})->wait;
    run_git('-C', $repodir, qw{add .})->wait;
    run_git('-C', $repodir, qw{commit -m}, 'initial commit')->wait;

    return $repodir;
}
