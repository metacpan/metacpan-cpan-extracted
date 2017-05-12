#!perl

use warnings;
use strict;
use Test::More tests => 1;
use Activator::Config;
use Activator::Log qw( :levels );
use Test::Exception;

#Activator::Log->level( 'DEBUG' );
my $config;

@ARGV = ();
my $proj_dir = "$ENV{PWD}/t/data/test_project";
push @ARGV, qq(--conf_path="$proj_dir"),  'test';


lives_ok {
   $config = Activator::Config->get_config( \@ARGV, undef, 1 );
} 'lives when project is arg';
