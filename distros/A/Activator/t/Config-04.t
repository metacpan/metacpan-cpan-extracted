#!perl

use warnings;
use strict;
use Test::More tests => 1;
use Activator::Config;
use Activator::Log qw( :levels );
use Test::Exception;

my $config;

$ENV{ACT_CONFIG_project} = 'test';

dies_ok {
   $config = Activator::Config->get_config( \@ARGV );
} 'dies when conf_path not set';
