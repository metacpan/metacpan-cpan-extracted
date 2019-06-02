#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok('Data::Context::Loader::DB');
    use_ok('Data::Context::Finder::DB');
    use_ok('Data::Context::Finder::DB::Schema');
    use_ok('Data::Context::Finder::DB::Schema::Result::Data');
}

diag( "Testing Data::Context::Loader::DB $Data::Context::Loader::DB::VERSION, Perl $], $^X" );
done_testing();
