#!perl

use warnings;
use strict;
use Test::More tests => 1;
use Activator::Config;
use Activator::Log qw( :levels );
use Test::Exception;

my $config;

dies_ok {
   $config = Activator::Config->get_config( \@ARGV );
} 'dies when project not set';
