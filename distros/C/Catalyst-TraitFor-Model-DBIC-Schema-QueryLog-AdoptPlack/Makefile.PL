#!/usr/bin/env perl

use maint::Maker;

all_from 'lib/Catalyst/TraitFor/Model/DBIC/Schema/QueryLog/AdoptPlack.pm';
requires 'Moose' => '1.21';
requires 'Catalyst::Component::InstancePerContext' => '0.001001';
requires 'Plack::Middleware::DBIC::QueryLog' => '0.05';
requires 'Scalar::Util';
test_requires 'Test::More' => '0.96';

tests_recursive;
