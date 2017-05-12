#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  App::AquariumHive
  App::AquariumHive::DB
  App::AquariumHive::DB::Result
  App::AquariumHive::DB::ResultSet
  App::AquariumHive::LogRole
  App::AquariumHive::Role
  App::AquariumHive::Tile
  App::AquariumHive::Plugin::AqHive
  App::AquariumHive::Plugin::AqHive::State
  App::AquariumHive::Plugin::Cron
  App::AquariumHive::Plugin::GemBird
  App::AquariumHive::Plugin::GemBird::Socket
  AquariumHive
  AquariumHive::Simulator
  DigitalX::AqHive
  DigitalX::AqHive::ORP
  DigitalX::AqHive::pH
  DigitalX::AqHive::EC
  DigitalX::AqHive::Temp
)) {
  use_ok($_);
}

done_testing;

