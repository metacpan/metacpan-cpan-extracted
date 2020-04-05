#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.10.0;

use lib 'lib';

use Encode;
use Test::More tests => 2;

chdir 'example';
require_ok('../bin/wrt-feed');

my $output_string;
my $output = sub {
  $output_string .= $_[0] . "\n";
};

my @local_argv = qw();
main($output, @local_argv);
ok(
  $output_string =~ m/<title>wrt/,
  "Probably have a feed..."
);
