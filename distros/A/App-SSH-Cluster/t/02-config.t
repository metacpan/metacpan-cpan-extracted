#!/usr/bin/env perl

use strict;
use warnings;

use App::SSH::Cluster;
use Test::Exception tests => 6;
use YAML::Tiny;

my %TEST_FILES;
foreach my $filename ( glob("t/conf/*.yml") ) {
   $TEST_FILES{ $filename =~ s|^t/conf/config-(.*)\.yml|$1|gr } = $filename;
}

lives_ok {
   App::SSH::Cluster->new( command => 'ls', config_file => $TEST_FILES{valid} )->_validate_config;
} 'creating a new instance of App::SSH::Cluster with a valid config lives';


foreach my $filename ( grep { $_ =~ m/missing/ } keys %TEST_FILES ) {
   my ($key) = $filename =~ m/missing-(.*)/;
   throws_ok {
      App::SSH::Cluster->new( 
         command     => 'ls', 
         config_file => $TEST_FILES{$filename},
      )->_validate_config;
   } qr/No '$key' key found in $TEST_FILES{$filename}/,
   "_validate_config dies when $key is missing from the configuration file";
}

throws_ok {
   App::SSH::Cluster->new(
      command     => 'ls',
      config_file => $TEST_FILES{'no-servers-defined'},
   )->_validate_config; 
} qr/Existing 'servers' key found in $TEST_FILES{'no-servers-defined'}/,
'_validate_config dies when there is a servers key defined, but no servers are listed';
