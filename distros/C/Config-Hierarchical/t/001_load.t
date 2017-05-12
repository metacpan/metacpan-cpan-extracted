
# t/001_load.t - check module loading

use strict ;
use warnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'Config::Hierarchical' ); } ;

{
my $config = new Config::Hierarchical() ;

is(defined $config, 1, 'default constructor') ;
isa_ok($config, 'Config::Hierarchical');

my $new_config = $config->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'Config::Hierarchical');
}

dies_ok
	{
	Config::Hierarchical::new () ;
	} "invalid constructor" ;

throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'new passed odd number of arguments' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments') ;
	$config->Get(NAME =>'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'Get passed odd number of arguments' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments') ;
	$config->GetHistory(NAME =>'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'GetHistorypassed odd number of arguments' ;

throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments') ;
	$config->IsLocked(NAME =>'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'IsLocked odd number of arguments' ;

throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments') ;
	$config->Lock(NAME =>'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'Lock odd number of arguments' ;

throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments') ;
	$config->Set(NAME =>'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'Set odd number of arguments' ;

throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments') ;
	$config->Unlock(NAME =>'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'Unlock odd number of arguments' ;

throws_ok
	{
	my $config = new Config::Hierarchical(NAME => 'odd arguments') ;
	$config->Exists(NAME =>'odd arguments', 'oops') ;
	} qr/Invalid number of argument/, 'Exists odd number of arguments' ;

my $alarm_reached = 0 ;
eval
	{
	local $SIG{ALRM} = sub {$alarm_reached++ ; die} ;
	alarm 1 ;
	
	eval
		{
		my $input = <STDIN> ;
		} ;
	
	alarm 0 ;
	} ;

alarm 0 ;

if($alarm_reached)
	{
	SKIP: 
		{
		skip 'Syntax ok and use strict (press key to run)', 1 ;
		}
	}
else
	{
	use Test::Strict;
	all_perl_files_ok();
	}
	