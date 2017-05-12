#!/usr/bin/perl

require Module::Build;
use strict;


my $build = Module::Build->new
  (
   dist_name => "AHA",
   dist_version_from => "lib/AHA.pm",
   dist_author => 'Roland Huss (roland@cpan.org)',
   dist_abstract => "Access modules for AVM's home automation system",
   installdirs => 'site',
   license => 'gpl',   
   requires => {
                "LWP::UserAgent" => 0,
                "Encode" => 0,
                "Digest::MD5" => 0
               },
   build_requires => {
                      "Module::Build" => "0.34",
                      "Test::More" => "0",
                     },                       
   configure_requires => { 'Module::Build' => 0.34 },
   keywords => [  "AVM", "AHA", "Fritz", "Dect!200" ]
  );

$build->create_build_script;

