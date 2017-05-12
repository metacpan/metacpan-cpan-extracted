# wantarray test

use strict ;
use warnings ;
use Test::Exception ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Test::NoWarnings qw(had_no_warnings) ;
use Test::Warn ;

use Config::Hierarchical ; 

{
local $Plan = {'wantarray' => 12} ;

my $config = new Config::Hierarchical
			(
			INITIAL_VALUES  =>
				[
				{NAME => 'CC', VALUE => 1},
				{NAME => 'LD', VALUE => 2},
				],
			) ;

my $cc = $config->Get(NAME => 'CC') ;
had_no_warnings("Get in scalar context") ; 

warning_like
	{
	$config->Get(NAME => 'CC') ;
	} qr/void context/i, "Get in void context";
	
my @cc_ld = $config->GetMultiple('CC', 'LD') ;
had_no_warnings("GetMultilpe in array context") ; 

my @cc = $config->GetMultiple('CC') ;
had_no_warnings("GetMultiple in array context") ; 

my @nothing = $config->GetMultiple() ;
had_no_warnings("GetMultiple in array context") ; 

warning_like
	{
	$config->GetMultiple('CC', 'LD') ;
	} qr/void context/i, "GetMultiple in void context";
	
warning_like
	{
	$config->GetMultiple('CC') ;
	} qr/void context/i, "GetMultiple, single value in void context";
	
warning_like
	{
	my $scalar = $config->GetMultiple('CC', 'LD') ;
	} qr/scalar context/i, "GetMultiple in scalar context";
	
warning_like
	{
	my $scalar = $config->GetMultiple('CC') ;
	} qr/scalar context/i, "GetMultiple, single value in scalar context";
	
my $hash_ref = $config->GetHashRef() ;
had_no_warnings("GetHashRef in scalar context") ; 

warning_like
	{
	$config->GetHashRef() ;
	} qr/void context/i, "GetHashRef in void context";
	
warning_like
	{
	my @array = $config->GetHashRef() ;
	} qr/array context/i, "GetHashRef in array context";

}