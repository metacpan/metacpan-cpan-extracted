#!/usr/bin/perl
use strict;
use Test::More tests => 2;
use_ok("DJabberd::Delivery::OfflineStorage::SQLite");
use_ok("DJabberd::Delivery::OfflineStorage::InMemoryOnly");
