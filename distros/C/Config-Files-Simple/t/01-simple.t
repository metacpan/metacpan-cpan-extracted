#!perl
use 5.006;
use strict;
use warnings;
use Path::Tiny;
use Hash::MD5 qw/sum/;
use Test::More tests => 7;

BEGIN {
    use_ok('Config::Files::Simple')           || print "Bail out!\n";
    require_ok('Config::Files::Simple::JSON') || print "Bail out!\n";
    require_ok('Config::Files::Simple::YAML') || print "Bail out!\n";
}

my $md5_hash = 'b034bf16eb12401e0affae696c012dc9';

is( sum( Config::Files::Simple::config_file( path('t/data/config.yml')->absolute, 'YAML' ) ), $md5_hash, 'set config by yaml' );

is( sum( Config::Files::Simple::config_file( path('t/data/config.json')->absolute, 'JSON' ) ), $md5_hash, 'set config by json' );

is(
    sum(
        Config::Files::Simple::config(
            {
                key01 => 'value01',
                key02 => 'value02',
                key03 => 'value03',
            }
        )
    ),
    $md5_hash,
    'set config by hash'
);

is( sum( Config::Files::Simple::config() ), $md5_hash, 'get configs' );

#config_file
