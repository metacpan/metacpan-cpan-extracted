#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 6;
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

# listing out of all source files

  my (@all_source_files) = $w->get_all_source_files();
  ok(
    scalar @all_source_files == 16,
    'got 16 source files from example archive, as expected'
  );

# listing entries like 2014/1/1 for an individual day:

  my (@all_day_entries) = $w->get_all_day_entries();
  ok(
    scalar @all_day_entries == 2,
    'got 2 day entries from example archive, as expected'
  );

# rendering static html files

# ok(
#   $w->render(sub { diag($_[0]); }),
#   'render stuff'
# );
