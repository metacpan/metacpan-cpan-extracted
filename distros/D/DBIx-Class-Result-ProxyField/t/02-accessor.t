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
$track->title('title of track');
is $track->track_title, $track->title, "object->public_name return object->database_name";

$track->track_title('new title');
is $track->title, 'new title', "object->public_name(value) set object database name";

