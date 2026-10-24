use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions::Process;

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));

# Copying and running the suite costs as much as the suite itself, so there is
# a switch to turn it off; a child run must never copy the suite again.
plan skip_all => 'the suite was already copied here for the space-in-path run'
    if $ENV{APP_ACTIONS_SPACE_PATH_CHILD};
plan skip_all => 'SPACE_PATH=0 turns off the space-in-path run'
    if defined $ENV{SPACE_PATH} && $ENV{SPACE_PATH} eq '0';
# Automated runs (CI, CPAN testers) skip it unless SPACE_PATH asks for it:
# under Devel::Cover the second run takes most of an hour.
plan skip_all => 'AUTOMATED_TESTING skips the space-in-path run; set SPACE_PATH=1 to run it'
    if $ENV{AUTOMATED_TESTING} && !$ENV{SPACE_PATH};
plan skip_all => 'the suite is already running from a path with spaces'
    if $root =~ / /;

# The copy is made here, not in the distribution, so the tests below exercise
# the code under test and not a stale duplicate.  What goes into it is what
# MANIFEST says the distribution ships, which is the list of files the suite
# may read: a test that starts reading a new file is covered here as soon as
# that file is in the distribution, rather than failing - or, worse, skipping -
# in this copy alone.  Modes are kept, because the hook is run rather than read.
my $manifest = File::Spec->catfile($root, 'MANIFEST');
open my $listing, '<', $manifest or die "cannot read '$manifest': $!\n";

my @shipped;
while (my $line = <$listing>) {
    next if $line =~ /\A#/;

    # make distdir rewrites MANIFEST with a description after each name, so
    # only the first field is the file.  A name cannot contain whitespace, so
    # this is the same list whichever form the file is in.
    my ($file) = split /\s+/, $line;
    next unless defined $file && length $file;

    push @shipped, $file;
}
close $listing;

my $temp = tempdir('app-actions space XXXX', TMPDIR => 1, CLEANUP => 1);
my $copy = File::Spec->catdir($temp, 'suite with spaces');
make_path($copy);

for my $file (@shipped) {
    my $from = File::Spec->catfile($root, split m{/}, $file);
    my $to   = File::Spec->catfile($copy, split m{/}, $file);

    die "MANIFEST lists '$file', which is not in the tree\n" unless -e $from;

    make_path(dirname($to));
    copy($from, $to) or die "cannot copy '$from' to '$to': $!\n";

    chmod((stat $from)[2] & 07777, $to)
        or die "cannot set the mode of '$to': $!\n";
}

like($copy, qr/ /, 'the copy lives under a path with spaces');

my $tests = File::Spec->catdir($copy, 't');
my $lib   = File::Spec->catdir($copy, 'lib');

opendir my $directory, $tests or die "cannot read '$tests': $!\n";
my @tests = sort grep { /\.t\z/ } readdir $directory;
closedir $directory;

ok(@tests, 'the copy contains the test suite');

my @failed;
{
    my $original = File::Spec->rel2abs(File::Spec->curdir);
    chdir $copy or die "cannot change to '$copy': $!\n";

    for my $test (@tests) {
        my $file = File::Spec->catfile($tests, $test);
        my ($stdout, $stderr, $status) = capture {
            local $ENV{APP_ACTIONS_SPACE_PATH_CHILD} = 1;
            App::Actions::Process::stream([ $^X, '-I' . $lib, $file ]);
        };

        my $ok = ok(
            $status == 0,
            "$test passes when the suite is run from a path with spaces",
        );

        next if $ok;

        push @failed, $test;
        diag "stdout:\n$stdout" if length $stdout;
        diag "stderr:\n$stderr" if length $stderr;
    }

    chdir $original or die "cannot return to '$original': $!\n";
}

is_deeply(\@failed, [], 'every test file passes from a path with spaces');

done_testing;
