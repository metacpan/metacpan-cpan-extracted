#!/usr/bin/perl
#
# Test running spin on a tree of files.
#
# Copyright 2021-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use File::Copy::Recursive qw(dircopy);
use Path::Tiny qw(path);
use POSIX qw(LC_ALL setlocale strftime);
use Test::DocKnot::Spin qw(fix_pointers is_spin_output_tree);

use Test::More;

# Force the C locale because some of the output intentionally uses localized
# month names and we have to force those to English for comparison of test
# results.
setlocale(LC_ALL, 'C');

# Expected output when spinning our tree of input files.
my $EXPECTED_OUTPUT = <<'OUTPUT';
Generating thread file .../changes.th
Generating RSS file .../changes.rss
Generating index file .../journal/index.th
Generating RSS file .../journal/index.rss
Generating RSS file .../journal/debian.rss
Generating RSS file .../journal/reviews.rss
Updating .../changes.rss
Spinning .../changes.html
Spinning .../index.html
Creating .../journal
Updating .../names.png
Spinning .../random.html
Creating .../reviews
Creating .../software
Creating .../usefor
Creating .../journal/2011-08
Updating .../journal/debian.rss
Updating .../journal/index.rss
Spinning .../journal/index.html
Updating .../journal/reviews.rss
Creating .../reviews/books
Creating .../software/docknot
Spinning .../software/index.html
Creating .../usefor/drafts
Spinning .../usefor/index.html
Spinning .../journal/2011-08/006.html
Spinning .../reviews/books/0-385-49362-2.html
Creating .../software/docknot/api
Converting .../software/docknot/changes.html
Spinning .../software/docknot/index.html
Converting .../software/docknot/readme.html
Updating .../usefor/drafts/draft-ietf-usefor-message-id-01.txt
Updating .../usefor/drafts/draft-ietf-usefor-posted-mailed-01.txt
Updating .../usefor/drafts/draft-ietf-usefor-useage-01.txt
Updating .../usefor/drafts/draft-lindsey-usefor-signed-01.txt
Converting .../software/docknot/api/app-docknot.html
OUTPUT

BEGIN { use_ok('App::DocKnot::Util', qw(print_fh)) }

require_ok('App::DocKnot::Spin');

# Copy the input tree to a new temporary directory since .rss files generate
# additional thread files.
my $tmpdir = Path::Tiny->tempdir();
my $datadir = path('t', 'data', 'spin');
my $input = $datadir->child('input');
dircopy($input, $tmpdir) or die "Cannot copy $input to $tmpdir: $!\n";
fix_pointers($tmpdir, $input);

# Spin a tree of files.
my $output = Path::Tiny->tempdir();
my $expected = $datadir->child('output');
my $spin = App::DocKnot::Spin->new({ 'style-url' => '/~eagle/styles/' });
my $stdout = capture_stdout { $spin->spin($tmpdir, $output) };
my $count = is_spin_output_tree($output, $expected, 'spin');
is($stdout, $EXPECTED_OUTPUT, 'Expected spin output');

# Create a bogus file in the output tree.
my $bogus = $output->child('bogus');
$bogus->mkpath();
$bogus->child('some-file')->spew_utf8("Some stuff\n");

# Spinning the same tree of files again should do nothing because of the
# modification timestamps.
$stdout = capture_stdout { $spin->spin($tmpdir, $output) };
is($stdout, q{}, 'Spinning again does nothing');

# The extra file shouldn't be deleted.
ok($bogus->is_dir(), 'Stray file and directory not deleted');

# Reconfigure spin to enable deletion, and run it again.  The only action
# taken should be to delete the stray file.
$spin
  = App::DocKnot::Spin->new({ delete => 1, 'style-url' => '/~eagle/styles/' });
$stdout = capture_stdout { $spin->spin($tmpdir, $output) };
is(
    $stdout,
    "Deleting .../bogus/some-file\nDeleting .../bogus\n",
    'Spinning with delete option cleans up',
);
ok(!$bogus->exists(), 'Stray file and directory was deleted');

# Override the title of the POD document and request a contents section.  Set
# the modification timestamp in the future to force a repsin.
my $pod_source = path('lib', 'App', 'DocKnot.pm')->realpath();
my $pointer_path = $tmpdir->child(
    'software', 'docknot', 'api', 'app-docknot.spin',
);
$pointer_path->spew_utf8(
    "format: pod\n",
    "path: $pod_source\n",
    "options:\n",
    "  contents: true\n",
    "  navbar: false\n",
    "title: 'New Title'\n",
);
utime(time() + 5, time() + 5, $pointer_path)
  or die "Cannot reset timestamps of $pointer_path: $!\n";
$stdout = capture_stdout { $spin->spin($tmpdir, $output) };
is(
    $stdout,
    "Converting .../software/docknot/api/app-docknot.html\n",
    'Spinning again regenerates the App::DocKnot page',
);
my $output_path = $output->child(
    'software', 'docknot', 'api', 'app-docknot.html',
);
my $page = $output_path->slurp_utf8();
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
my $versions_path = $tmpdir->child('.versions');
my $versions = $versions_path->slurp_utf8();
my $new_date = strftime('%Y-%m-%d %T', localtime(time() + 10));
$versions =~ s{ \d{4}-\d\d-\d\d [ ] [\d:]+ }{$new_date}xms;
$versions_path->chmod(0644);
$versions_path->spew_utf8($versions);
$stdout = capture_stdout { $spin->spin($tmpdir, $output) };
is(
    $stdout,
    "Spinning .../software/docknot/index.html\n",
    'Spinning again regenerates the DocKnot page',
);

# Report the end of testing.
done_testing($count + 12);
