#!perl

use strict;
use warnings;
use Test::More;

use_ok('ASPEER::MakeMaker::Markdown::Publish');
ok(ASPEER::MakeMaker::Markdown::Publish->isa('ASPEER::MakeMaker'),
    'plugin inherits shared MakeMaker integration');
use_ok('ASPEER::MakeMaker::Markdown::Publish::MM');
use_ok('ASPEER::MakeMaker::Markdown::Publish::MM::Constant');

done_testing();
