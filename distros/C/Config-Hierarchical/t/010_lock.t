# lock test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn ;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Config::Hierarchical ; 

{
local $Plan = {'locking' => 13} ;

my $config = new Config::Hierarchical() ;
$config->Set(NAME => 'CC', VALUE => 'gcc', LOCK => 1) ;

ok($config->IsLocked(NAME => 'CC'), 'config locked') ;

$config->Unlock(NAME => 'CC') ;
is($config->IsLocked(NAME => 'CC'), 0, 'config unlocked') ;

$config->Lock(NAME => 'CC') ;
ok($config->IsLocked(NAME => 'CC'), 'config locked') ;

throws_ok
	{
	$config->Set(NAME => 'WHATEVER', VALUE => 1, LOCK => 1) ;
	$config->Set(NAME => 'WHATEVER', VALUE => 2, LOCK => 0) ;
	} qr/was locked and couldn't be set/, "can't unlock without FORCE_LOCK" ;

warning_like
	{
	$config->Set(NAME => 'CC', VALUE => 'gcc2', FORCE_LOCK => 1, LOCK => 0) ;
	} qr/Forcing locked/i, "forcing warning";

is($config->Get(NAME => 'CC'), 'gcc2', 'forced lock') ;
is($config->IsLocked(NAME => 'CC'), 0, 'config unlocked') ;


$config->Lock(NAME => 'CC') ;
dies_ok
	{
	$config->Set(NAME => 'CC', VALUE => 'gccx') ;
	} "can't set locked variable" ;
	
dies_ok
	{
	$config->Lock(NAME => 'UNEXISTANT') ;
	} "can't locked unexisting variable" ;

dies_ok
	{
	$config->Lock(NAME => 'CC', CATEGORY => 'NOT_EXISTS') ;
	} "can't lock unexisting category" ;
	
dies_ok
	{
	$config->Unlock(NAME => 'CC', CATEGORY => 'NOT_EXISTS') ;
	} "can't unlock unexisting category" ;
	
dies_ok
	{
	$config->Lock() ;
	} "un-named variable" ;

dies_ok
	{
	$config->Unlock() ;
	} "un-named variable" ;

}

{
local $Plan = {'coverage' => 3} ;

my (@info_messages);
my $info = sub {push @info_messages, @_} ;

my $config = new Config::Hierarchical
				(
				NAME            => 'extra coverage test',
				VERBOSE         => 1,
				INITIAL_VALUES  => [{NAME => 'CC', VALUE => 'gcc'}],
				INTERACTION     => 
					{
					INFO  => $info,
					},
				) ;

$config->Lock(FILE => 'file1', LINE => 'line1', NAME => 'CC') ;
like($info_messages[-1], qr/file1:line1/, 'extra coverage') ;

$config->Unlock(FILE => 'file2', LINE => 'line2', NAME => 'CC') ;
like($info_messages[-1], qr/file2:line2/, 'extra coverage') ;

$config->IsLocked(FILE => 'file3', LINE => 'line3', NAME => 'CC') ;
like($info_messages[-1], qr/file3:line3/, 'extra coverage') ;

$config->Unlock(NAME => 'NOT_EXIST') ;
}

{
local $Plan = {'locking in category' => 5} ;

my $config = new Config::Hierarchical() ;
$config->Set(NAME => 'CC', VALUE => 'gcc', LOCK => 1) ;

ok($config->IsLocked(NAME => 'CC', CATEGORY => 'CURRENT'), 'config locked') ;

$config->Unlock(NAME => 'CC', CATEGORY => 'CURRENT') ;
is($config->IsLocked(NAME => 'CC'), 0, 'config unlocked') ;
is($config->IsLocked(NAME => 'NOT_EXIST'), undef, 'variable does not exist') ;

dies_ok
	{
	$config->IsLocked(CATEGORY => 'NOT_EXISTS', NAME => 'CC') ;
	} "Can't query unexisting category" ;

dies_ok
	{
	$config->IsLocked() ;
	} "un-named variable" ;

}


