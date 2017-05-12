#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $fixer = Catmandu::Fix->new(fixes => [
	q|add_field(my.deep.field,foo)|,
	q|add_field(my.deep.array.$append,red)|,
	q|add_field(my.deep.array.$append,green)|,
	q|add_field(my.deep.array.$append,blue)|,
	q|marc_add('999', ind1 => 4 , ind2 => 1 , a => 'test')| ,
	q|marc_add('998', ind1 => 4 , ind2 => 1 , a => '$.my.deep.field')| ,
	q|marc_add('997', ind1 => 4 , ind2 => 1 , a => '$.my.deep.array')| ,
]);
my $record = $fixer->fix({});

ok exists $record->{record}, 'created a marc record';
is $record->{record}->[0]->[0] , '999', 'created 999 tag';
is $record->{record}->[0]->[1] , '4', 'created 999 ind1';
is $record->{record}->[0]->[2] , '1', 'created 999 ind2';
is $record->{record}->[0]->[3] , 'a', 'created 999 subfield a';
is $record->{record}->[0]->[4] , 'test', 'created 999 subfield a value';

is $record->{record}->[1]->[0] , '998', 'created 998 tag';
is $record->{record}->[1]->[1] , '4', 'created 998 ind1';
is $record->{record}->[1]->[2] , '1', 'created 998 ind2';
is $record->{record}->[1]->[3] , 'a', 'created 998 subfield a';
is $record->{record}->[1]->[4] , 'foo', 'created 998 subfield a value';

is $record->{record}->[2]->[0] , '997', 'created 997 tag';
is $record->{record}->[2]->[1] , '4', 'created 997 ind1';
is $record->{record}->[2]->[2] , '1', 'created 997 ind2';
is $record->{record}->[2]->[3] , 'a', 'created 997 subfield a';
is $record->{record}->[2]->[4] , 'red', 'created 997 subfield a value';
is $record->{record}->[2]->[5] , 'a', 'created 997 subfield a';
is $record->{record}->[2]->[6] , 'green', 'created 997 subfield a value';
is $record->{record}->[2]->[7] , 'a', 'created 997 subfield a';
is $record->{record}->[2]->[8] , 'blue', 'created 997 subfield a value';

done_testing 20;

