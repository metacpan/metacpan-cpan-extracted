#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Admin::DSNManager;

# -------------------

my($m) = DBIx::Admin::DSNManager -> new(verbose => 1) || die $DBIx::Admin::DSNManager::errstr;

$m -> report;
