#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

use_ok 'DBIx::SimpleMigration';
use_ok 'DBIx::SimpleMigration::Client';
use_ok 'DBIx::SimpleMigration::Migration';
