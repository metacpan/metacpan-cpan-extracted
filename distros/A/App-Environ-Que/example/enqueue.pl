#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use lib 'lib';
$ENV{APPCONF_DIRS} = 'example';

use AE;
use App::Environ;
use App::Environ::Que;

App::Environ->send_event('initialize');

my $que = App::Environ::Que->instance('main');

my $cv = AE::cv;
$que->enqueue(
  type => 'sendTelegram',
  args => { to => 00000000, text => 'test' },
  sub { $cv->send; }
);
$cv->recv;

App::Environ->send_event('finalize:r');
