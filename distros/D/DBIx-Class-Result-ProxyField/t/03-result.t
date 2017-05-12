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

my $track = $schema->resultset('Track')->find(1);

# test accessor
$track->track_title('title of track');
$track->update();
my $track1 = $schema->resultset('Track')->find(1);
is $track1->title, 'title of track', "update without arguments works";

$track->update({title => 'new title of track'});
my $track2 = $schema->resultset('Track')->find(1);
is $track2->title, 'new title of track', "update without arguments works";

