#!/usr/bin/perl
# clucene_test.pl - test program for CLucene perl wrapper
#
# Copyright(c) 2005 Peter Edwards <peterdragon@users.sourceforge.net>
# All rights reserved. This package is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.

use strict;
use warnings;

use Carp;
use Data::Dumper;

use CLucene;

{
	my $cl = clnew();

	basictest($cl);

	eval { basicfail($cl); };
	print "  $@\n";

	empty($cl);

	loaddocs($cl);

	search($cl);

	multisearch($cl);

	empty($cl);

	print "\nAll tests successful\n";

	exit(0);
}

sub clnew
{
	print "clnew\n";
	my $cl = CLucene->new( path => "./index" );
	$cl;
}

sub empty
{
	my $cl = shift;
	$cl->empty;
}

sub basictest
{
	my $cl = shift;
	print "basictest\n";
	$cl->open;
	$cl->close;	
}

sub basicfail
{
	my $cl = shift;
	print "basicfail\n";
	$cl->open( path => "./index2", create => 0 );
}

sub loaddocs
{
	my $cl = shift;
	print "loaddocs\n";
	$cl->open( path => "./index", create => 1 );
	$cl->new_document;
	$cl->add_field( field => "ref", value => "doc1");
	$cl->add_field( field => "cnt", value => "some content");
	$cl->add_date ( field => "add_dt", value => time );
	my $s = $cl->document_info;
	print "Document to add: $s\n";
	$cl->insert_document
		or confess "Failed to insert_document";
	$cl->close;
}

sub search
{
	my $cl = shift;
	print "search\n";
	$cl->open( path => "./index", create => 0 );
	$cl->search( query => "some", field => "cnt" )
		or confess "search failed";
	my $searchinfo = $cl->search_info;
	print "Search info: $searchinfo\n";
	my $hitcount = $cl->hitcount;
	print "Got $hitcount hits\n";
	my $gothit = $hitcount;
	while ($gothit)
	{
		my $ret;
		($ret,my $valref,my $valreflen) = $cl->getfield( field => "ref" );
		confess "Failed getfield ref" unless $ret;
		($ret,my $valcnt,my $valcntlen) = $cl->getfield( field => "cnt" );
		confess "Failed getfield cnt" unless $ret;
		my $valadddt = $cl->getdatefield( field => "add_dt" )
			or confess "Failed getdatefield add_dt";
		print("Document: ref: [$valreflen] $valref, cnt: [$valcntlen] $valcnt, add_dt: $valadddt\n");
		$gothit = $cl->nexthit;
	}
	$cl->close;
}

sub multisearch
{
	my $cl = shift;
	print "multisearch\n";
	$cl->open( path => "./index", create => 0 );
	$cl->searchmultifieldsflagged( query => "some", fields_aptr => ["cnt"], flags_aptr => [ $cl->NORMAL_FIELD ] )
		or confess "searchmultifieldsflagged failed";
	my $searchinfo = $cl->search_info;
	print "Search info: $searchinfo\n";
	my $hitcount = $cl->hitcount;
	print "Got $hitcount hits\n";
	my $gothit = $hitcount;
	while ($gothit)
	{
		my $ret;
		($ret,my $valref,my $valreflen) = $cl->getfield( field => "ref" );
		confess "Failed getfield ref" unless $ret;
		($ret,my $valcnt,my $valcntlen) = $cl->getfield( field => "cnt" );
		confess "Failed getfield cnt" unless $ret;
		my $valadddt = $cl->getdatefield( field => "add_dt" )
			or confess "Failed getdatefield add_dt";
		print("Document: ref: [$valreflen] $valref, cnt: [$valcntlen] $valcnt, add_dt: $valadddt\n");
		$gothit = $cl->nexthit;
	}
	$cl->close;
}
