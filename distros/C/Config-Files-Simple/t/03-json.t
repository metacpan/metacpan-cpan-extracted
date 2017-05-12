#!perl
use 5.006;
use strict;
use warnings;
use Path::Tiny;
use Hash::MD5 qw/sum/;
use Test::More tests => 4;

BEGIN {
    use_ok('Config::Files::Simple::JSON') || print "Bail out!\n";
}

my $o_yaml = new_ok("Config::Files::Simple::JSON");

isa_ok $o_yaml, "Config::Files::Simple::JSON", "Config::Files::Simple::JSON->new";

my $md5_hash = 'b034bf16eb12401e0affae696c012dc9';
is( sum( $o_yaml->config_file( path('t/data/config.json')->absolute ) ), $md5_hash, 'set config by json' );
