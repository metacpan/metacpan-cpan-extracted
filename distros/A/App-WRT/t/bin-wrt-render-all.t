#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.10.0;

use lib 'lib';

use Encode;
use Test::More tests => 3;
use App::WRT::Mock::FileIO;

chdir 'example/blog';
require_ok('../../bin/wrt-render-all');

my $output_string;
my $output = sub {
  $output_string .= $_[0] . "\n";
};

my $mock_io = App::WRT::Mock::FileIO->new();
my @local_argv = ();

main($output, $mock_io, @local_argv);

ok(
  $output_string =~ 'rendered 26 entries',
  'rendered expected number of entries'
) or diag($output_string);

ok(
  $output_string =~ 'seconds',
  'log mentions seconds'
) or diag($output_string);
