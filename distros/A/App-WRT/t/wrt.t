#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 4;
use App::WRT;

chdir 'example';

# 'configuration';

  ok(
    my $w = App::WRT::new_from_file('wrt.json'),
    "Got WRT object."
  );

# 'individual subroutine tests';

  ok(
    $w->recent_month() =~ m/\d{4}\/\d{1,2}/,
    'recent_month returns a month'
  );

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

# rendering static html files

# ok(
#   $w->render(sub { diag($_[0]); }),
#   'render stuff'
# );
