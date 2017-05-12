#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use t::lib::Utils;
use t::app::Main;

plan tests => 1;

my $schema = t::app::Main->connect('dbi:SQLite:t/example.db');
$schema->deploy({add_drop_table => 1});
populate_database($schema);

use t::app::Main::Result::Track;
# becarful to respect the order of loading module
t::app::Main::Result::Track->load_components(qw/ Result::ProxyField Result::ColumnData /);
t::app::Main::Result::Track->init_proxy_field();

my $track = $schema->resultset('Track')->find(1);

my $columns_data = {
  'cd_id' => $track->cdid,
  'track_title' => $track->title,
  'trackid' => $track->trackid
};
is_deeply($track->columns_data, $columns_data, "object->columns_data return object with public name");

