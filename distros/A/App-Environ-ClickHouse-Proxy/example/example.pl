#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use lib 'lib';
$ENV{APPCONF_DIRS} = 'example';

use App::Environ;
use App::Environ::ClickHouse::Proxy;

App::Environ->send_event('initialize');

my $ch_proxy = App::Environ::ClickHouse::Proxy->instance;

$ch_proxy->send( 'INSERT INTO test (dt_part,dt,id) VALUES (?,?,?);',
  '2017-09-09', '2017-09-09 12:26:03', 1 );

App::Environ->send_event('finalize:r');
