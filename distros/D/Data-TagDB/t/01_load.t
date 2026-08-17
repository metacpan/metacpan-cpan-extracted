#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 15;

use_ok('Data::TagDB');
use_ok('Data::TagDB::Cache');
use_ok('Data::TagDB::Cloudlet');
use_ok('Data::TagDB::Exporter');
use_ok('Data::TagDB::Factory');
use_ok('Data::TagDB::Iterator');
use_ok('Data::TagDB::Link');
use_ok('Data::TagDB::LinkIterator');
use_ok('Data::TagDB::Metadata');
use_ok('Data::TagDB::Migration');
use_ok('Data::TagDB::MultiIterator');
use_ok('Data::TagDB::Relation');
use_ok('Data::TagDB::Tag');
use_ok('Data::TagDB::WeakBaseObject');
use_ok('Data::TagDB::WellKnown');

exit 0;
