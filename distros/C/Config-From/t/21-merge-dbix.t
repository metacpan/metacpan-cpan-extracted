#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use FindBin '$Bin';
use lib 't/lib';
use Schema::Config;

use_ok('Config::From');
use_ok('Config::From::Backend::DBIx');
use_ok('Config::From::Backend::File');

my $bckfile = Config::From::Backend::File->new(file => 't/conf/file1.yml', debug =>1);

my $schema = Schema::Config->connect('dbi:SQLite:dbname=:memory:')
    or die "Failed to connect to database";
$schema->deploy;
$schema->_populate;


ok( my $bckdbix = Config::From::Backend::DBIx->new( table => 'Config', schema => $schema ),
    'new backend DBIx');

isa_ok($bckdbix->datas, 'HASH', 'backend');


ok( my $config = Config::From->new( backends => [ $bckfile, $bckdbix] ), 'new config with backends (File && DBIx)');

my $good = {
          'titi' => 'dbix4',
          'abc' => {
                     'def' => {
                                'ghi' => 'dbix5'
                              }
                   },
          'toto' => {
                      'tete' => 'dbix2',
                      'titi' => 'file1',
                      'tutu' => 'file1'
                    },
          'tata' => 'file1'
      };

is_deeply( $config->config, $good, "the result is good" );
