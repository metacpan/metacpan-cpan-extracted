#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use lib 'lib';

use Encode;
use JSON;
use Test::More tests => 19;

# Does the module load?

require_ok('App::WRT');

chdir 'example';

# configuration

  ok(
    my $w = App::WRT::new_from_file('wrt.json'),
    "got WRT object."
  );

# individual subroutine tests

  my $datestamp = $w->datestamp('2014/1/1/test_entry');
  like(
    $datestamp,
    qr{test_entry},
    'datestamp for a fragment references that fragment'
  ) or diag($datestamp);

# icon rendering

  my $with_icon = $w->display('icon_test');

  like(
    $with_icon,
    qr/img src/,
    'icon_test has an image in it'
  ) or diag($with_icon);

  my $icon_textfile = $w->icon_markup('icon_test/textfile', 'alt');
  is(
    $icon_textfile,
    q{<img src="https://example.com/icon_test/textfile.icon.png"
 width="48" height="58"
 alt="alt" />},
    'got expected icon for icon_test/textfile'
  ) or diag($icon_textfile);

  my $icon_dir = $w->icon_markup('icon_test/dir', 'alt');
  is(
    $icon_dir,
    q{<img src="https://example.com/icon_test/dir/index.icon.png"
 width="48" height="58"
 alt="alt" />},
    'got expected icon for icon_test/dir'
  ) or diag($icon_dir);

  my $icon_subentry = $w->icon_markup('icon_test/dir/subentry', 'alt');
  is(
    $icon_subentry,
    q{<img src="https://example.com/icon_test/dir/subentry.icon.png"
 width="48" height="58"
 alt="alt" />},
    'got expected icon for icon_test/dir/subentry'
  ) or diag($icon_subentry);

# feed rendering

  my $with_stars = $w->display('2014/1/2');

  like(
    $with_stars,
    qr/✨/s,
    '2014/1/2 contains some stars which we also expect to show up in the feed'
  );

  my $feed = $w->feed_print_recent();

  like(
    $feed,
    qr/✨/s,
    'feed contains some stars'
  ) or diag($feed);

  my $json_feed = $w->feed_print_json();
  my $JSON = JSON->new->utf8->pretty;
  my $feed_hashref = $JSON->decode(encode('UTF-8', $json_feed));

  ok(
    length $json_feed,
    'got some sort of a JSON Feed'
  ) or diag($json_feed);

  ok(
    defined $feed_hashref->{title},
    'got a JSON Feed with a title'
  ) or diag($feed_hashref);

# not expanding entries with wrt-noexpand

  my $with_noexpand = $w->display('noexpand_test');
  # diag($with_noexpand);
  unlike(
    $with_noexpand,
    qr/SHOULD NOT DISPLAY/,
    'noexpand_test does not contain text of sub-entry do_not_expand_me'
  ) or diag($with_noexpand);

# displaying default entry when no entries are given

  my $with_no_entries = $w->display();
  like(
    $with_no_entries,
    qr{\Q<title>wrt::new</title>\E},
    'display the default entry (new) when no entries are given'
  ) or diag($with_no_entries);

# contents of year index files

  my $plaintext_year = $w->display('2012');
  like(
    $plaintext_year,
    qr/\QI'm a year which is just a flatfile.\E/,
    "2012 as plaintext year comes through."
  ) or diag($plaintext_year);

  my $plaintext_year_index = $w->display('2013');
  like(
    $plaintext_year_index,
    qr/\QI'm an index file for an entire year.\E/,
    "2013's plaintext year index comes through."
  ) or diag($plaintext_year_index);

# titles

  my $title = $w->get_title('2014/1/2');
  is(
    $title,
    'Thursday, January 2, 2014',
    'got expected title for 2014/1/2'
  ) or diag($title);

# next / prev page navigation

  my ($page_navigation) = $w->page_navigation('2014/1/2');
  like(
    $page_navigation,
    qr{2014/1/1},
    "got previous title in page navigation for 2014/1/2"
  ) or diag($page_navigation);

  $page_navigation = $w->page_navigation('2014/1/1');
  like(
    $page_navigation,
    qr{2014/1/2},
    "got next title in page navigation for 2014/1/2"
  ) or diag($page_navigation);

  my ($tag_list) = $w->entry_tag_list('tags_test');
  like(
    $tag_list,
    qr{<a href="https://example.com/animals/platypus">animals/platypus</a>},
    'got link to an expected tag index for tags_test'
  );
