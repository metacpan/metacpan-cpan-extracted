#! perl
use warnings;
use strict;

use Algorithm::FloodControl::Backend::Cache::FastMmap;
our $be = "Algorithm::FloodControl::Backend::Cache::FastMmap";
use Cache::FastMmap;
use Test::More tests => 6;
use File::Temp;
my $temp_file = File::Temp->new->filename;
require 't/tlib.pm';
tlib::test_backend( 'Cache::FastMmap', { share_file => $temp_file })
