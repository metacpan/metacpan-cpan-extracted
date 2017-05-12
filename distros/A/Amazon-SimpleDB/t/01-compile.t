#!perl

use strict;
use warnings;

use lib 'lib';

use Test::More;

plan tests => 8;

use_ok('Amazon::SimpleDB::Domain');
use_ok('Amazon::SimpleDB::ErrorResponse');
use_ok('Amazon::SimpleDB::GetAttributesResponse');
use_ok('Amazon::SimpleDB::Item');
use_ok('Amazon::SimpleDB::ListDomainsResponse');
use_ok('Amazon::SimpleDB::QueryResponse');
use_ok('Amazon::SimpleDB::Response');
use_ok('Amazon::SimpleDB');

