#!/usr/bin/perl -T

use lib 't/tests';
use Test::ComplexGraph;
use Test::CyclicGraph;
use Test::ObjectsAsNodes;
use Test::Parameters;
use Test::SingletonGraph;
use Test::StartNodeInclusion;

Test::Class->runtests;
