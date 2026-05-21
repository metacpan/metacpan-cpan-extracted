#!/usr/bin/perl

use strict;
use warnings;
use App::CriticDB::DB::Index;
use Test::More tests=>1;

subtest 'initialization types'=>sub{
	plan tests=>7;
	my $index;
	#
	$index=App::CriticDB::DB::Index->new();
	is(ref($index),'App::CriticDB::DB::Index::Id','default:  Id');
	#
	$index=App::CriticDB::DB::Index->new(values=>'id',prefix=>'p:');
	ok(defined($index),'Created');
	is(ref($index),'App::CriticDB::DB::Index::Id','type:  Id');
	is($$index{prefix},'p:','Prefix stored');
	#
	$index=App::CriticDB::DB::Index->new(values=>'set');
	ok(defined($index),'Created');
	is(ref($index),'App::CriticDB::DB::Index::Set','type  Set');
	#
	eval { App::CriticDB::DB::Index->new(values=>'bogus') };
	ok($@,'invalid type');
};
