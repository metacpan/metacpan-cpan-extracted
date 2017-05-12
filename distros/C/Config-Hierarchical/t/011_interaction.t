# interaction sub test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Config::Hierarchical ; 

{
local $Plan = {'INTERACTION' => 7} ;

my (@info_messages, @warn_messages, @die_messages, @debug_messages);

my $info = sub {push @info_messages, [@_]} ;
my $warn = sub {push @warn_messages, [@_]} ;
my $die = sub {push @die_messages, [@_]} ;
my $debug = sub {push @debug_messages, [@_]} ;
	
my $config = new Config::Hierarchical
				(
				NAME            => 'verbose test',
				VERBOSE         => 1,
				INITIAL_VALUES  => [{NAME => 'CC', VALUE => 1}],
				INTERACTION     => 
					{
					INFO  => $info,
					WARN  => $warn,
					DIE   => $die,
					DEBUG => $debug,
					},
				) ;

is(@info_messages, 2, "Create and Set messages") ;

is(@debug_messages, 1, "Set debug hook") ;

$config->Set(NAME => 'A', VALUE => 'A', LOCK => 1) ;
is(@debug_messages, 2, "Set debug hook") ;

my $cc = $config->Get(NAME => 'CC') ;
is(@debug_messages, 3, "Get debug hook") ;

my $cc2 = $config->Get(NAME => 'CC', CATEGORY => 'CURRENT') ;
is(@debug_messages, 4, "Get debug hook") ;

$config->Set(NAME => 'A', VALUE => 'forced A', FORCE_LOCK => 1) ;
is(@warn_messages, 1, "forcing lock messages") ;

#~ $config->GetHashRef('argument') ;
#~ is(@die_messages, 1, "dying") ;

use Data::TreeDumper ;

(@info_messages, @warn_messages, @die_messages, @debug_messages) = () ;
my @tuples = $config->GetKeyValueTuples() ;
is(@debug_messages, 3, "GetKeyValueTuples") or diag DumpTree \@debug_messages;

}

