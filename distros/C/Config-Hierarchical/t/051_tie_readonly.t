# test

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Config::Hierarchical ; 
use Config::Hierarchical::Tie::ReadOnly ; 


{
local $Plan = {'Tie::ReadOnly' => 11} ;

my $config = new Config::Hierarchical
			(
			NAME => 'config',
			
			CATEGORY_NAMES   => ['A', 'B'],
			DEFAULT_CATEGORY => 'B',
			
			INITIAL_VALUES  =>
				[
				{CATEGORY => 'A', NAME => 'CC1', VALUE => '1'},
				{CATEGORY => 'B', NAME => 'CC2', VALUE => '2'},
				{CATEGORY => 'A', NAME => 'CC3', VALUE => '3'},
				{CATEGORY => 'B', NAME => 'CC4', VALUE => '4'},
				{CATEGORY => 'A', NAME => 'CC5', VALUE => '5'},
				] ,
			) ;

throws_ok
	{
	my %hash ;
	tie %hash, "Config::Hierarchical::Tie::ReadOnly",  'string' ;
	} qr/Argument must be a 'Config::Hierarchical' object/, 'bad argument to tie constructor' ;

my %hash ;
tie %hash, "Config::Hierarchical::Tie::ReadOnly",  $config ;

is_deeply([sort keys %hash], [qw( CC1 CC2 CC3 CC4 CC5)], 'keys');
is($hash{CC1}, '1', 'FETCH') ;

ok(exists($hash{CC2}), 'exists') ;
ok(! exists($hash{CC6}), 'not exists') ;

is(scalar(%hash), 5, 'SCALAR') ;

warning_like
	{
	my $CC6 = $hash{CC6} ;
	is ($CC6, undef, 'variable does not exists') ;
	} qr/Variable 'CC6' doesn't exist/i, 'variable does not exist';

throws_ok
	{
	$hash{CC5} = 6 ;
	} qr/This hash is read only/, 'STORE' ;
	
throws_ok
	{
	delete $hash{CC1} ;
	} qr/This hash is read only/, 'DELETE' ;
	
throws_ok
	{
	%hash = () ;
	} qr/This hash is read only/, 'CLEAR' ;

}
