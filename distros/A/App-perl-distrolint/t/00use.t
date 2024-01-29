#!/usr/bin/perl

use v5.36;

use Test2::V0;

require App::perl::distrolint;

require App::perl::distrolint::Check::DeprecatedFeatures;
require App::perl::distrolint::Check::Editorconfig;
require App::perl::distrolint::Check::FilePaths;
require App::perl::distrolint::Check::HardTabs;
require App::perl::distrolint::Check::NoStrictRefs;
require App::perl::distrolint::Check::Pod;
require App::perl::distrolint::Check::StrictAndWarnings;
require App::perl::distrolint::Check::Unimport;
require App::perl::distrolint::Check::Test2;
require App::perl::distrolint::Check::UseUTF8;
require App::perl::distrolint::Check::UseVERSION;
require App::perl::distrolint::Check::VersionVar;

pass "Modules loaded";
done_testing;
