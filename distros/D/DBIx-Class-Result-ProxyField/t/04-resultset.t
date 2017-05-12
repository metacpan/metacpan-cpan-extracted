#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use t::lib::Utils;
use t::app::Main;

plan tests => 2;

my $schema = t::app::Main->connect('dbi:SQLite:t/example.db');
$schema->deploy({add_drop_table => 1});
populate_database($schema);

use t::app::Main::Result::Track;
t::app::Main::Result::Track->load_components(qw/ Result::ProxyField /);
t::app::Main::Result::Track->init_proxy_field();

my $track1 = $schema->resultset('Track')->find(1);
my @track2 = $schema->resultset('Track')->search({track_title => $track1->title});
is $track1->id, $track2[0]->id, "search is possible with public name";

my $track3 = $schema->resultset('Track')->create({track_title => "this is a track title", cd_id => 1});
my $track4 = $schema->resultset('Track')->find($track3->id);
is_deeply $track3->track_title, $track4->track_title, "create is possible with public name";

