#!/usr/bin/env perl

use strict;
use warnings;

use App::SSH::Cluster;
use Test::Exception;
use Test::More tests => 3;

throws_ok {
  App::SSH::Cluster->new;
} qr/\QAttribute (command) is required\E/,
'creating an instance of App::SSH::Cluster without a command fails';

lives_ok {
   App::SSH::Cluster->new( command => 'ls' );
} 'creating an instance of App::SSH::Cluster lives';

is( App::SSH::Cluster->new( command => 'ls' )->config_file,
    "$ENV{HOME}/.app-clusterssh.yml",
    'default value of config_file points to .app-clusterssh.yml in $HOME'
);
