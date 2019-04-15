#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib 'lib';

use Encode;
use Test::More tests => 4;
use App::WRT;

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

# feed rendering
  my $feed = decode('UTF-8', $w->display($w->{feed_alias}));
  # diag($feed);

  # look for ✨:
  ok(
    $feed =~ m/✨/s,
    'feed contains some stars'
  );

# rendering static html files

# ok(
#   $w->render(sub { diag($_[0]); }),
#   'render stuff'
# );
