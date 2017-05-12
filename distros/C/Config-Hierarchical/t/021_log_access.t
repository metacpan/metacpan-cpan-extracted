# set_get_default test

use strict ;
use warnings ;
use Test::Exception ;
use Test::Warn ;
use Test::NoWarnings qw(had_no_warnings) ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Data::TreeDumper ;

use Config::Hierarchical ; 

{
local $Plan = {'log' => 7} ;

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES         => [ 'PARENT', 'LOCAL', 'CURRENT', 'OVERRIDING_1', 'OVERRIDING_2'],
				DEFAULT_CATEGORY       => 'CURRENT',
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					},
						
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'PARENT', NAME => 'A',  VALUE => '1'},
					{NAME => 'A',  VALUE => '1'},
					{NAME => 'B',  VALUE => '3'},
					] ,
					
				LOG_ACCESS => 1,
				) ;

my $value = $config->Get(NAME => 'A') ;
$value = $config->Get(NAME => 'B') ;

warning_like
	{
	$value = $config->Get(NAME => 'C') ;
	} qr/Variable 'C' doesn't exist/, 'does not exist' ;

# get from specifi category
$value = $config->Get(NAME => 'A', CATEGORIES_TO_EXTRACT_FROM => ['PARENT']) ;

# check the log
my $access_log = $config->GetAccessLog() ;

is(scalar(@{$access_log}), 4, 'right number of  entries in access log') or diag DumpTree $access_log ;
is($access_log->[0]{NAME}, 'A', 'right variable');
is($access_log->[1]{NAME}, 'B', 'right variable');
is($access_log->[2]{NAME}, 'C', 'right variable');
is($access_log->[3]{NAME}, 'A', 'right variable');
is_deeply($access_log->[3]{CATEGORIES_TO_EXTRACT_FROM}, ['PARENT'], 'categories are logged');
}


{
local $Plan = {'log not used' => 1} ;

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES         => [ 'PARENT', 'LOCAL', 'CURRENT', 'OVERRIDING_1', 'OVERRIDING_2'],
				DEFAULT_CATEGORY       => 'CURRENT',
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					},
						
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'PARENT', NAME => 'A',  VALUE => '1'},
					{NAME => 'A',  VALUE => '1'},
					{NAME => 'B',  VALUE => '3'},
					] ,
				) ;

my $value = $config->Get(NAME => 'A') ;
$value = $config->Get(NAME => 'B') ;

# get from specifi category
$value = $config->Get(NAME => 'A', CATEGORIES_TO_EXTRACT_FROM => ['PARENT']) ;

my $access_log = $config->GetAccessLog() ;
is_deeply($access_log, [], 'empty log');
}
