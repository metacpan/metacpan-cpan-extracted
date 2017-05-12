#!/usr/bin/perl

use Test::More;
use Test::Compile;

all_pm_files_ok || BAIL_OUT ("You've got compilation issues!");
