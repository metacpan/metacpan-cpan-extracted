#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::More tests => 2;
use App::WRT;

# Check that we can handle a site with an "index" file in the archive root.

chdir 'example/flat_site';

ok(
  my $w = App::WRT::new_from_file('wrt.json'),
  "got WRT object for a site with root index"
);

ok(
  $w->display() =~ m/front page/,
  'front page contains index contents'
);
