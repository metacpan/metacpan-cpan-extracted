#! /usr/bin/perl

use strict ;
use warnings ;
use Carp ;

use Data::TreeDumper ;
use Data::TreeDumper::OO ;
use Data::Dumper ;

my $sub = sub {} ;

my %tree = 
	(
	A => 
		{
		a => 
			{
			}
		, bbbbbb => $sub
		, c123 => $sub
		, d => \$sub
		}
		
	, C =>	{
		b =>
			{
			a => 
				{
				a => 
					{
					}
					
				, b => sub
					{
					}
				, c => 42
				}
				
			}
		}
	, ARRAY => [qw(elment_1 element_2 element_3)]
	) ;

my $s = \%tree ;

print Dumper($s) ;

#-------------------------------------------------------------------
# package global setup data
#-------------------------------------------------------------------

$Data::TreeDumper::Useascii     = 0 ;
$Data::TreeDumper::Maxdepth     = 2 ;
$Data::TreeDumper::Virtualwidth =  80 ;

print Data::TreeDumper::DumpTree($s, "Using package data") ;
print Data::TreeDumper::DumpTree($s, "Using package data with override", MAX_DEPTH => 1, DISPLAY_NUMBER_OF_ELEMENTS_OVER_MAX_DEPTH => 1) ;

#-------------------------------------------------------------------
# OO interface
#-------------------------------------------------------------------

my $dumper = new Data::TreeDumper::OO() ;
$dumper->UseAnsi(1) ;
$dumper->SetMaxDepth(2) ;
$dumper->SetVirtualWidth(80) ;

print $dumper->Dump($s, "Using OO interface") ;
 

print DumpTrees
	(
	  [$s, "DumpTrees1", MAX_DEPTH => 1]
	, [$s, "DumpTrees2", MAX_DEPTH => 2]
	, USE_ASCII => 1
	) ;

print $dumper->DumpMany
	(
	  [$s, "DumpMany1", MAX_DEPTH => 1]
	, [$s, "DumpMany2", MAX_DEPTH => 2, USE_ASCII => 0]
	, USE_ASCII => 1
	) ;


#-------------------------------------------------------------------
# Renderers
#-------------------------------------------------------------------

# simple ASCII dump
print DumpTree($s, 'ASCII:', RENDERER => 'ASCII') ;

# DHTML rendering
my $dump =  DumpTree($s, 'DHTML:', RENDERER => 'DHTML') ;

$| = 1 ;
print "15 first lines of the DHTML dump:\n" ;
print ((split(/(\n)/, $dump))[0 .. 29]) ;

# un existant rendering
DumpTree($s, 'unexistant!', RENDERER => 'UNEXISTANT') ;

