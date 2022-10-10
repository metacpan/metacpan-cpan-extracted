#!/usr/bin/env perl

use lib 't/lib';
use Test::More 0.86;
use Test::DBIx::Class 
  -schema_class => 'Schema',
  qw(:resultsets);


ok my $user = User->create({name=>'Foo', password=>'abc123'});

is $user->get_column('name'), 'Foo';
is $user->get_column_storage('name'), '';

ok $user->name('Boo');
is $user->name, 'Boo';
ok $user->get_column('name'), 'Boo';
is $user->get_column_storage('name'), 'Foo';

done_testing;
