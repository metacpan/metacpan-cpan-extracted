#!/usr/bin/perl

use strict;
use warnings;
use App::CriticDB::DB::Index;
use Test::More tests=>4;

subtest 'initialization'=>sub{
	plan tests=>2;
	my $index=App::CriticDB::DB::Index->new(values=>'set');
	ok(defined($index),'Created');
	ok(defined($$index{kset}),'Set (empty)');
};

subtest 'insertion'=>sub{
	plan tests=>1;
	my $index=App::CriticDB::DB::Index->new(values=>'set');
	$index->add(qw/apple one/);
	$index->add(qw/apple two/);
	$index->add(qw/cherry two/);
	$index->add(qw/cherry three/);
	is(scalar($index->all()),4,'All entries created');
};

subtest 'selection'=>sub {
	plan tests=>9;
	my @res;
	my $index=App::CriticDB::DB::Index->new(values=>'set');
	$index->add(qw/apple one/);
	$index->add(qw/apple two/);
	$index->add(qw/cherry two/);
	$index->add(qw/cherry three/);
	is(scalar($index->all('apple')), 2,'All (apple,undef)');
	is(scalar($index->all('cherry')),2,'All (cherry,undef)');
	is(scalar($index->all('grape')), 0,'All (grape,undef)');
	is(scalar($index->all(undef,'one')),   1,'All (undef,one)');
	is(scalar($index->all(undef,'two')),   2,'All (undef,two)');
	is(scalar($index->all(undef,'three')), 1,'All (undef,three)');
	@res=sort $index->all('apple');     is_deeply(\@res,[qw/one two/],'Shape (apple,undef)');
	@res=sort $index->all(undef,'two'); is_deeply(\@res,[qw/apple cherry/],'Shape (undef,two)');
	@res=$index->all(); is(ref($res[0]),'ARRAY','Shape (undef,undef)');
};

subtest 'removal'=>sub{
	plan tests=>6;
	my $index=App::CriticDB::DB::Index->new(values=>'set');
	$index->add(qw/apple  one/);
	$index->add(qw/apple  two/);
	$index->add(qw/cherry two/);
	$index->add(qw/cherry three/);
	$index->add(qw/grape  three/);
	$index->remove('cherry','grape');
	is(scalar($index->all()),2,'Removal:  cherry+grape');
	is(scalar($index->all('cherry')),0,'Removal:  cherry');
	is(scalar($index->all('grape')), 0,'Removal:  grape');
	is(scalar($index->all('apple')),2,'Retained:  apple');
	$index->remove('two');
	is(scalar($index->all('apple')),1,'Value removal:  two');
	$index->remove();
	is(scalar($index->all()),1,'No-op');
};
