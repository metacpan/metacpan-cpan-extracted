#!/usr/bin/perl

use strict;
use warnings;
use App::CriticDB::Report;
use Perl::Critic::Violation;
use PPI::Statement;
use Test::More tests=>1;

subtest 'Default'=>sub {
	plan tests=>5;
	my ($report,@violations,$expect,$violation);
	#
	$expect='';
	$report=App::CriticDB::Report->new(violations=>\@violations);
	is($report->text(),$expect,'No violations');
	#
	$expect.="f1: d1 at line 3, column 2.  (Severity: 1)\n";
	$violation=Perl::Critic::Violation->new('d1','e1',bless({},'PPI::Statement'),'1');
	@$violation{qw/_filename _policy _location/}=('f1','P::1',[0,1,2,3,'f1']);
	push @violations,$violation;
	$report=App::CriticDB::Report->new(violations=>\@violations);
	is($report->text(),$expect,'One violation');
	is($report->text($violation),$expect,'Single violation formatting');
	#
	$expect.="f2: d2 at line 4, column 3.  (Severity: 2)\n";
	$violation=Perl::Critic::Violation->new('d2','e2',bless({},'PPI::Statement'),'2');
	@$violation{qw/_filename _policy _location/}=('f2','P::2',[1,2,3,4,'f2']);
	push @violations,$violation;
	$report=App::CriticDB::Report->new(violations=>\@violations);
	is($report->text(),$expect,'Two violations');
	#
	$expect='f1 P::1 1;f2 P::2 2;';
	$report=App::CriticDB::Report->new(verbose=>'%f %p %s;',violations=>\@violations);
	is($report->text(),$expect,'Verbose/formatting');
};

