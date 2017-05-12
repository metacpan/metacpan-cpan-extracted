#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use_ok('Data::Context');
use_ok('Data::Context::Actions');
use_ok('Data::Context::Finder');
use_ok('Data::Context::Finder::File');
use_ok('Data::Context::Instance');
use_ok('Data::Context::Loader');
use_ok('Data::Context::Loader::File');
use_ok('Data::Context::Loader::File::XML');
use_ok('Data::Context::Loader::File::JSON');
use_ok('Data::Context::Loader::File::JS');
use_ok('Data::Context::Loader::File::YAML');
use_ok('Data::Context::Log');
use_ok('Data::Context::Util');


diag( "Testing Data::Context $Data::Context::VERSION, Perl $], $^X" );
done_testing;
