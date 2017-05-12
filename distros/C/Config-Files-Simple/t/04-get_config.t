#!perl
use 5.006;
use strict;
use warnings;
use Path::Tiny;
use Hash::MD5 qw/sum/;
use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok('Config::Files::Simple') || print "Bail out!\n";
}

dies_ok( sub { Config::Files::Simple::config; }, 'no config expecting to die' );

#config_file
