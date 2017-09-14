#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use lib 'lib';
$ENV{APPCONF_DIRS} = 'example';

use App::Environ;
use App::Environ::ClickHouse;
use Data::Dumper;

App::Environ->send_event('initialize');

my $CH = App::Environ::ClickHouse->instance;

my $data = $CH->selectall_hash('SELECT * FROM default.test');
say Dumper $data;

App::Environ->send_event('finalize:r');
