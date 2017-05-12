#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';

use_ok('Config::From');

my $good = {
          'toto' => {
                      'titi' => 'file1',
                      'tutu' => 'file1',
                      'tete' => 'file2'
                    },
          'titi' => 'file2',
          'tata' => 'file1'
      };

use_ok('Config::From::Backend::File');
my $bckfile1 = Config::From::Backend::File->new(file => 't/conf/file1.yml', debug =>1);
my $bckfile2 = Config::From::Backend::File->new(file => 't/conf/file2.yml');

ok( my $config = Config::From->new( backends => [ $bckfile1, $bckfile2] ), 'new config with backends');
is_deeply( $config->config, $good, "the result is good" );
