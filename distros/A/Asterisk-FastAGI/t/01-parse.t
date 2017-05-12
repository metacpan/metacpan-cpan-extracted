#!/usr/bin/perl -w

use strict;
use Asterisk::FastAGI;
use Test::More tests => 12;

{
	my %args1;
	$args1{server}{input} = {
		'callerid' => 'jaywhy',
		'context' => 'default',
		'request' => 'agi://localhost/agi_handler?foo=bar&BLAH=blam&',
	};	
	
	my $test1 = bless \%args1, "Asterisk::FastAGI"; 
	$test1->_parse_request();
	
	ok( $test1->{server}{method} eq 'agi_handler' );
	
	ok( $test1->param('foo') eq 'bar' );
	ok( $test1->param('BLAH') eq 'blam' );
	
	my $params = $test1->param();
	ok( $params->{foo} eq 'bar' );
	ok( $params->{BLAH} eq 'blam' );
	
	ok( $test1->input('callerid') eq 'jaywhy' );
	ok( $test1->input('context') eq 'default' );
	
	my $input = $test1->input();
	
	ok( $input->{callerid} eq 'jaywhy' );
	ok( $input->{context} eq 'default' );
}

{
	my %args2;
	$args2{server}{input} = {
		'callerid' => 'jaywhy',
		'request' => 'agi://192.168.1.100/other_handler',
	};
	
	my $test2 = bless \%args2, "Asterisk::FastAGI"; 
	$test2->_parse_request();
	
	ok( $test2->{server}{method} eq 'other_handler' );
	
	ok( $test2->input('callerid') eq 'jaywhy' );
	my $input = $test2->input();
	ok( $input->{callerid} eq 'jaywhy' );
}

