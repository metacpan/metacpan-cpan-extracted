#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib 'lib';

use Encode;
use Test::More tests => 12;

# Does the module load?

require_ok('App::WRT');

chdir 'example';

# 'configuration';

  ok(
    my $w = App::WRT::new_from_file('wrt.json'),
    "Got WRT object."
  );

# 'individual subroutine tests';

  my $datestamp = $w->datestamp('2014/1/1/test_entry');
  # diag($datestamp);

  ok(
    $datestamp =~ m{test_entry},
    'datestamp for a fragment references that fragment'
  );

# icon rendering

  my $with_icon = $w->display('icon_test');
  # diag($with_icon);

  ok(
    $with_icon =~ m/img src/,
    'icon_test has an image in it'
  );

  my $icon_textfile = $w->icon_markup('icon_test/textfile', 'alt');
  # diag($icon_textfile);
  ok(
    $icon_textfile eq q{<img src="https://example.com/icon_test/textfile.icon.png"
 width="48" height="58"
 alt="alt" />},
    'got expected icon for icon_test/textfile'
  );

  my $icon_dir = $w->icon_markup('icon_test/dir', 'alt');
  # diag($icon_dir);
  ok(
    $icon_dir eq q{<img src="https://example.com/icon_test/dir/index.icon.png"
 width="48" height="58"
 alt="alt" />},
    'got expected icon for icon_test/dir'
  );

  my $icon_subentry = $w->icon_markup('icon_test/dir/subentry', 'alt');
  # diag($icon_subentry);
  ok(
    $icon_subentry eq q{<img src="https://example.com/icon_test/dir/subentry.icon.png"
 width="48" height="58"
 alt="alt" />},
    'got expected icon for icon_test/dir/subentry'
  );

# feed rendering

  my $feed = decode('UTF-8', $w->display($w->{feed_alias}));
  # diag($feed);

  # look for ✨:
  ok(
    $feed =~ m/✨/s,
    'feed contains some stars'
  );

# not expanding entries with wrt-noexpand

  my $with_noexpand = $w->display('noexpand_test');
  # diag($with_noexpand);
  ok(
    $with_noexpand !~ m/SHOULD NOT DISPLAY/,
    'noexpand_test does not contain text of sub-entry do_not_expand_me'
  );

# displaying default entry when no entries are given:

  my $with_no_entries = $w->display();
  # diag($with_no_entries);
  ok(
    $with_no_entries =~ m{\Q<title>wrt::new</title>\E},
    'display the default entry (new) when no entries are given'
  );

# contents of year index files:

  my $plaintext_year = $w->display('2012');
  ok(
    $plaintext_year =~ m/\QI'm a year which is just a flatfile.\E/,
    "2012 as plaintext year comes through."
  );

  my $plaintext_year_index = $w->display('2013');
  ok(
    $plaintext_year_index =~ m/\QI'm an index file for an entire year.\E/,
    "2013's plaintext year index comes through."
  );

# displaying years 
