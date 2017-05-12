#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use ok 'Catalyst::Model::Adaptor::Base';
use ok 'Catalyst::Model::Adaptor';
use ok 'Catalyst::Model::Factory';
use ok 'Catalyst::Model::Factory::PerRequest';
