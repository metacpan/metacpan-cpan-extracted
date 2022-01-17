#!/usr/bin/perl
#
# Tests for App::DocKnot::Spin::Sitemap (.sitemap file handling).
#
# Copyright 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use File::Spec;
use Test::RRA qw(is_file_contents);

use Test::More tests => 10;

require_ok('App::DocKnot::Spin::Sitemap');

# Parse a complex .sitemap file.
my $datadir = File::Spec->catfile('t', 'data', 'spin', 'sitemap');
my $path = File::Spec->catfile($datadir, 'complex');
my $sitemap = App::DocKnot::Spin::Sitemap->new($path);
isa_ok($sitemap, 'App::DocKnot::Spin::Sitemap');

# Check the generated sitemap.
my $output = join(q{}, $sitemap->sitemap());
my $expected = File::Spec->catfile($datadir, 'complex.html');
is_file_contents($output, $expected, 'sitemap output');

# Unknown page.
my @links = $sitemap->links('/unknown');
is_deeply(\@links, [], 'links for unknown page');
my @navbar = $sitemap->navbar('/unknown');
is_deeply(\@navbar, [], 'navbar for unknown page');

# Check links and navbar for a page near a --- boundary, which may not be
# exercised by the test of spinning a tree of files.
@links = $sitemap->links('/faqs/soundness-inn.html');
my @expected = (
    q{  <link rel="next" href="soundness-cnews.html"}
      . qq{ title="Soundness for C News" />\n},
    qq{  <link rel="up" href="./" title="FAQs and Documentation" />\n},
    qq{  <link rel="top" href="../" />\n},
);
is_deeply(\@links, \@expected, 'links output');
@navbar = $sitemap->navbar('/faqs/soundness-inn.html');
@expected = (
    qq{<table class="navbar"><tr>\n},
    qq{  <td class="navleft"></td>\n},
    qq{  <td>\n},
    qq{    <a href="../">Russ Allbery</a>\n},
    qq{    &gt; <a href="./">FAQs and Documentation</a>\n},
    qq{  </td>\n},
    q{  <td class="navright"><a href="soundness-cnews.html">}
      . qq{Soundness for C News</a>&nbsp;&gt;</td>\n},
    qq{</tr></table>\n},
);
is_deeply(\@navbar, \@expected, 'navbar output');

# Check links for a page with long adjacent titles to test the wrapping.
@links = $sitemap->links('/notes/cvs/basic-usage.html');
@expected = (
    qq{  <link rel="previous" href="why.html"\n},
    qq{        title="Why put a set of files into CVS?" />\n},
    qq{  <link rel="next" href="command-summary.html"\n},
    qq{        title="Short CVS command summary" />\n},
    qq{  <link rel="up" href="./" title="CVS" />\n},
    qq{  <link rel="top" href="../../" />\n},
);
is_deeply(\@links, \@expected, 'links output with wrapping');

# Check error handling.
eval {
    $path = File::Spec->catfile($datadir, 'invalid');
    App::DocKnot::Spin::Sitemap->new($path);
};
is($@, "invalid line 3 in $path\n", 'invalid sitemap file');
# Check error handling.
eval {
    $path = File::Spec->catfile($datadir, 'duplicate');
    App::DocKnot::Spin::Sitemap->new($path);
};
is(
    $@,
    "duplicate entry for /faqs/comments.html in $path (line 4)\n",
    'sitemap file with duplicates',
);
