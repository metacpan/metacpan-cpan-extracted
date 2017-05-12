#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Exception;
use S3;

for my $package ('DBD::SQLite', 'SQL::Translator') {
  eval "require $package";
  plan skip_all => "API tests require $package, " if $@;
}

lives_ok sub { S3->schema->deploy }, 'Schema deployed sucessfuly';

## Basic API
my $rs = S3->my_books;
isa_ok($rs, 'DBIx::Class::ResultSet', 'Got the expected resultset');

my $not_found = S3->my_books(-1);
ok(!defined $not_found, 'Find for non-existing ID, undef');

$rs = S3->my_books({id => 2});
isa_ok($rs, 'DBIx::Class::ResultSet', 'Got a resultset');


## Now with real data
my $love = S3->my_books->create({title => 'Love your Catalyst'});
ok($love, 'Got something');
isa_ok($love, 'Schema::Result::MyBooks', '... and it seems a MyBook');

my $hate = S3->my_books->create({title => 'Hate ponies'});
ok($hate, 'Second book ok');
isa_ok($hate, 'Schema::Result::MyBooks', '... proper class at least');

is($hate->title, S3->my_books($hate->id)->title, 'Find shortcut works');
is(
  $hate->title,
  S3->my_books({id => $hate->id})->first->title,
  'Search shortcut works'
);

is(
  $love->title,
  S3->my_books(undef, { sort => 'title DESC' })->first->title,
  'Search without contitions shortcut works'
);

## Use unique keys with find
my $a1 = S3->authors->create({ id => 1, oid => 10});

is($a1->id, S3->authors(1)->id, 'Find by primary key works');
is($a1->id, S3->authors(\'oid_un', 10)->id, 'Find by unique key works');

done_testing();
