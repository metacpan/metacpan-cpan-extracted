#!/usr/bin/env perl

use lib 't/lib';
use Test::More 0.86;
use Test::DBIx::Class 
  -schema_class => 'Schema',
  qw(:resultsets);

ok my $artist = Artist->create({name=>'Foo', foo=>'aaa', result=>'result'});
ok $artist->spork, 'THERE IS NO SPROK';
ok $artist->foo, 'aaa';
ok $artist->result, 'result';
ok $artist->foo('ddd');
ok $artist->foo, 'dddd';

ok my $country = Country->create({name=>'Foo', foo=>'aaa', result=>'result'});
ok $country->spork, 'THERE IS NO SPROK';
ok $country->foo, 'aaa';
ok $country->result, 'result';
ok $country->foo('ddd');
ok $country->foo, 'dddd';

done_testing;
