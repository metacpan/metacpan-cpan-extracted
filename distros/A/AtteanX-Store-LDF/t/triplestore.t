use strict;
use warnings;
use Test::More;
use Test::Roo;


with 'Test::Attean::TripleStore', 'Test::Attean::Store::LDF::Role::CreateStore';
run_me;

done_testing;
