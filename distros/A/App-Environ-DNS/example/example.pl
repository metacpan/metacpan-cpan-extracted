#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use lib 'lib';

use App::Environ;
use App::Environ::DNS;

App::Environ->send_event('initialize');

my $pid = fork();
if ($pid) {
  say 'Parent';
}
else {
  say 'Worker';
  App::Environ->send_event('postfork');
  ## Now we have correct AnyEvent::DNS and AnyEvent::DNS::Resolver
}

App::Environ->send_event('finalize:r');
