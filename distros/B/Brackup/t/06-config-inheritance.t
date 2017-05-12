# -*-perl-*-

use strict;
use Test::More;
use FindBin qw($Bin);
use Brackup::Config;

my ($config);

my %source_defaults = (
  noatime => 1,
  chunk_size => '64MB',
  merge_files_under => '1kB',
  smart_mp3_chunking => 1,
);
my %target_defaults = (
  type => 'Ftp',
  ftp_host => 'myserver',
  ftp_user => 'myusername',
  ftp_password => 'mypassword',
  path => '.',
);
my %override = (
  home_weekly => {
    chunk_size => '96MB',
  },
  home_monthly => {
    chunk_size => '128MB',
  },
  ftp_home => {
    path => 'home',
  },
  ftp_images => {
    path => 'images',
  },
);

ok($config = Brackup::Config->load("$Bin/misc/brackup.conf"), "misc/brackup.conf loaded");

is($config->{'SOURCE:defaults'}->value($_), $source_defaults{$_}, "source defaults $_ ok")
  for sort keys %source_defaults;

is($config->{'SOURCE:home'}->value($_), $source_defaults{$_}, "home $_ ok")
  for sort keys %source_defaults;

is($config->{'SOURCE:home_weekly'}->value($_), $override{home_weekly}{$_} || $source_defaults{$_}, "home_weekly $_ ok")
  for sort keys %source_defaults;

is($config->{'SOURCE:home_monthly'}->value($_), $override{home_monthly}{$_} || $source_defaults{$_}, "home_monthly $_ ok")
  for sort keys %source_defaults;

is($config->{'TARGET:ftp_defaults'}->value($_), $target_defaults{$_}, "target ftp_defaults $_ ok")
  for sort keys %target_defaults;

is($config->{'TARGET:ftp_home'}->value($_), $override{ftp_home}{$_} || $target_defaults{$_}, "ftp_home $_ ok")
  for sort keys %target_defaults;

is($config->{'TARGET:ftp_images'}->value($_), $override{ftp_images}{$_} || $target_defaults{$_}, "ftp_images $_ ok")
  for sort keys %target_defaults;

done_testing;

