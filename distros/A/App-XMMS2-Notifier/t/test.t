#!/usr/bin/perl
use v5.14;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('App::XMMS2::Notifier') };

#########################

can_ok('App::XMMS2::Notifier', qw/run notify_libnotify/);
