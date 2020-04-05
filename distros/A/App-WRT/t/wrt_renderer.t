#!/usr/bin/env perl

use strict;
use warnings;
use 5.10.0;

use lib 'lib';

use Data::Dumper;
use Test::More tests => 1;

use App::WRT;
use App::WRT::Mock::FileIO;
use App::WRT::Renderer;

chdir 'example';
my $config_file = 'wrt.json';
my $wrt = App::WRT::new_from_file($config_file);

my $log_string = '';

my $renderer = App::WRT::Renderer->new(
  $wrt,
  sub { $log_string .= join '', @_; },
  App::WRT::Mock::FileIO->new(),
);

ok(
  $renderer->render(),
  'successful mock render'
);

# diag($log_string);
