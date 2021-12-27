#!/usr/bin/perl
#
# Test running spin on a tree of files.
#
# Copyright 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use Cwd qw(getcwd);
use File::Copy::Recursive qw(dircopy);
use File::Spec ();
use File::Temp ();
use Perl6::Slurp qw(slurp);
use POSIX qw(LC_ALL setlocale strftime);
use Test::DocKnot::Spin qw(is_spin_output_tree);

use Test::More;

# Force the C locale because some of the output intentionally uses localized
# month names and we have to force those to English for comparison of test
# results.
setlocale(LC_ALL, 'C');

# Expected output when spinning our tree of input files.
my $EXPECTED_OUTPUT = <<'OUTPUT';
Generating thread file .../changes.th
Generating RSS file .../changes.rss
Updating .../changes.rss
Spinning .../changes.html
Spinning .../index.html
Updating .../names.png
Spinning .../random.html
Creating .../journal
Generating index file .../journal/index.th
Generating RSS file .../journal/index.rss
Generating RSS file .../journal/debian.rss
Generating RSS file .../journal/reviews.rss
Updating .../journal/debian.rss
Updating .../journal/index.rss
Spinning .../journal/index.html
Updating .../journal/reviews.rss
Creating .../journal/2011-08
Spinning .../journal/2011-08/006.html
Creating .../reviews
Creating .../reviews/books
Spinning .../reviews/books/0-385-49362-2.html
Creating .../software
Spinning .../software/index.html
Creating .../software/docknot
Spinning .../software/docknot/index.html
Creating .../software/docknot/api
Converting .../software/docknot/api/app-docknot.html
Creating .../usefor
Spinning .../usefor/index.html
Creating .../usefor/drafts
Updating .../usefor/drafts/draft-ietf-usefor-message-id-01.txt
Updating .../usefor/drafts/draft-ietf-usefor-posted-mailed-01.txt
Updating .../usefor/drafts/draft-ietf-usefor-useage-01.txt
Updating .../usefor/drafts/draft-lindsey-usefor-signed-01.txt
OUTPUT

BEGIN { use_ok('App::DocKnot::Util', qw(print_fh)) }

require_ok('App::DocKnot::Spin');

# Copy the input tree to a new temporary directory since .rss files generate
# additional thread files.  Replace the POD pointer since it points to a
# relative path in the source tree, but change its modification timestamp to
# something in the past.
my $tmpdir = File::Temp->newdir();
my $datadir = File::Spec->catfile('t', 'data', 'spin');
my $input = File::Spec->catfile($datadir, 'input');
dircopy($input, $tmpdir->dirname)
  or die "Cannot copy $input to $tmpdir: $!\n";
my $pod_source = File::Spec->catfile(getcwd(), 'lib', 'App', 'DocKnot.pm');
my $pointer_path = File::Spec->catfile(
    $tmpdir->dirname, 'software', 'docknot', 'api',
    'app-docknot.spin',
);
chmod(0644, $pointer_path);
open(my $fh, '>', $pointer_path);
print_fh($fh, $pointer_path, "format: pod\n");
print_fh($fh, $pointer_path, "path: $pod_source\n");
close($fh);
my $old_timestamp = time() - 10;

# Spin a tree of files.
my $output = File::Temp->newdir();
my $expected = File::Spec->catfile($datadir, 'output');
my $spin = App::DocKnot::Spin->new({ 'style-url' => '/~eagle/styles/' });
my $stdout = capture_stdout {
    $spin->spin($tmpdir->dirname, $output->dirname);
};
my $count = is_spin_output_tree($output, $expected, 'spin');
is($stdout, $EXPECTED_OUTPUT, 'Expected spin output');

# Create a bogus file in the output tree.
my $bogus = File::Spec->catfile($output->dirname, 'bogus');
my $bogus_file = File::Spec->catfile($bogus, 'some-file');
mkdir($bogus);
open($fh, '>', $bogus_file);
print {$fh} "Some stuff\n" or die "Cannot write to $bogus_file: $!\n";
close($fh);

# Spinning the same tree of files again should do nothing because of the
# modification timestamps.
$stdout = capture_stdout {
    $spin->spin($tmpdir->dirname, $output->dirname);
};
is($stdout, q{}, 'Spinning again does nothing');

# The extra file shouldn't be deleted.
ok(-d $bogus, 'Stray file and directory not deleted');

# Reconfigure spin to enable deletion, and run it again.  The only action
# taken should be to delete the stray file.
$spin
  = App::DocKnot::Spin->new({ delete => 1, 'style-url' => '/~eagle/styles/' });
$stdout = capture_stdout {
    $spin->spin($tmpdir->dirname, $output->dirname);
};
is(
    $stdout,
    "Deleting .../bogus/some-file\nDeleting .../bogus\n",
    'Spinning with delete option cleans up',
);
ok(!-e $bogus, 'Stray file and directory was deleted');

# Override the title of the POD document and request a contents section.  Set
# the modification timestamp in the future to force a repsin.
open($fh, '>>', $pointer_path);
print_fh($fh, $pointer_path, "format: pod\n");
print_fh($fh, $pointer_path, "path: $pod_source\n");
print_fh($fh, $pointer_path, "options:\n  contents: true\n  navbar: false\n");
print_fh($fh, $pointer_path, "title: 'New Title'\n");
close($fh);
utime(time() + 5, time() + 5, $pointer_path)
  or die "Cannot reset timestamps of $pointer_path: $!\n";
$stdout = capture_stdout {
    $spin->spin($tmpdir->dirname, $output->dirname);
};
is(
    $stdout,
    "Converting .../software/docknot/api/app-docknot.html\n",
    'Spinning again regenerates the App::DocKnot page',
);
my $output_path = File::Spec->catfile(
    $output->dirname, 'software', 'docknot', 'api', 'app-docknot.html',
);
my $page = slurp($output_path);
like(
    $page,
    qr{ <title> New [ ] Title </title> }xms,
    'POD title override worked',
);
like($page, qr{ <h1> New [ ] Title </h1> }xms, 'POD h1 override worked');
like($page, qr{ Table [ ] of [ ] Contents }xms, 'POD table of contents');

# Set the time back so that it won't be generated again.
utime(time() - 5, time() - 5, $pointer_path)
  or die "Cannot reset timestamps of $pointer_path: $!\n";

# Now, update the .versions file at the top of the input tree to change the
# timestamp to ten seconds into the future.  This should force regeneration of
# only the software/docknot/index.html file.
my $versions_path = File::Spec->catfile($tmpdir->dirname, '.versions');
my $versions = slurp($versions_path);
my $new_date = strftime('%Y-%m-%d %T', localtime(time() + 10));
$versions =~ s{ \d{4}-\d\d-\d\d [ ] [\d:]+ }{$new_date}xms;
chmod(0644, $versions_path);
open(my $versions_fh, '>', $versions_path);
print {$versions_fh} $versions or die "Cannot write to $versions_path: $!\n";
close($versions_fh);
$stdout = capture_stdout {
    $spin->spin($tmpdir->dirname, $output->dirname);
};
is(
    $stdout,
    "Spinning .../software/docknot/index.html\n",
    'Spinning again regenerates the DocKnot page',
);

# Report the end of testing.
done_testing($count + 12);
