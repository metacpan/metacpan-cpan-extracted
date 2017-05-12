# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);

use Data::TreeDumper ;
use Data::TreeDumper::Utils  qw(:all) ;

{
local $Plan = {'first_nsort_last_filter' => 1} ;

my $dump = DumpTree
			(
			{
			ABC => 1,
			ZZZ =>  1,
			A => 1,
			B => 1,
			},
			'structure:',

			FILTER => \&first_nsort_last_filter,
			FILTER_ARGUMENT =>
				{
				AT_START => ['ZZZ'],
				AT_END => [qr/AB/],
				},
			) ;

my $expected_dump = <<EOD ;
structure:
|- ZZZ = 1  [S1]
|- A = 1  [S2]
|- B = 1  [S3]
`- ABC = 1  [S4]
EOD

is($dump, $expected_dump, 'first_nsort_last_filter-fixed') ;
}

{
local $Plan = {'first_nsort_last_filter' => 1} ;

my $dump = DumpTree
			(
			{
			AXC => 1,
			ZZZ =>  1,
			A => 1,
			B2 => 1,
			B => 1,
			REMOVE => 1,
			EVOMER => 1,
			C => 1,
			D => 1,
			E => 1,
			},
			'structure:',

			FILTER => \&first_nsort_last_filter,
			FILTER_ARGUMENT =>
				{
				REMOVE => ['REMOVE', qr/EVO/],
				AT_START_FIXED => ['ZZZ', qr/B/],
				AT_START => ['ZZZ'], # already taken by AT_START_FIXED
				AT_END => ['C', 'A'],
				AT_END_FIXED => [qr/AX/],
				},
			) ;

my $expected_dump = <<EOD ;
structure:
|- ZZZ = 1  [S1]
|- B = 1  [S2]
|- B2 = 1  [S3]
|- D = 1  [S4]
|- E = 1  [S5]
|- A = 1  [S6]
|- C = 1  [S7]
`- AXC = 1  [S8]
EOD

is($dump, $expected_dump, 'first_nsort_last_filter') ;
}

{
local $Plan = {'keys_order' => 1} ;

my $dump = DumpTree
			(
			{
			AXC => 1,
			ZZZ =>  1,
			A => 1,
			B2 => 1,
			B => 1,
			REMOVE => 1,
			EVOMER => 1,
			C => 1,
			D => 1,
			E => 1,
			},
			'structure:',

  			keys_order
				(
				REMOVE => ['REMOVE', qr/EVO/],
				AT_START_FIXED => ['ZZZ', qr/B/],
				AT_START => ['ZZZ'], # already taken by AT_START_FIXED
				AT_END => ['C', 'A'],
				AT_END_FIXED => [qr/AX/],
				),
			) ;

my $expected_dump = <<EOD ;
structure:
|- ZZZ = 1  [S1]
|- B = 1  [S2]
|- B2 = 1  [S3]
|- D = 1  [S4]
|- E = 1  [S5]
|- A = 1  [S6]
|- C = 1  [S7]
`- AXC = 1  [S8]
EOD

is($dump, $expected_dump, 'keys_order') ;
}

{
local $Plan = {'no_sort_filter' => 1} ;

use Tie::IxHash ;
tie my %hash, 'Tie::IxHash', B => 1, Z => 1, A => 1 ;

my $dump = DumpTree
			(
			\%hash,
			'An IxHash hash:',
			FILTER => \&no_sort_filter,
			) ;
			
my $expected_dump = <<EOD ;
An IxHash hash:
|- B = 1  [S1]
|- Z = 1  [S2]
`- A = 1  [S3]
EOD

is($dump, $expected_dump, 'no_sort_filter') ;
}
    
{
local $Plan = {'hash_keys_sorter' => 1} ;

use Tie::IxHash ;
tie my %hash, 'Tie::IxHash', B => 1, Z => 1, A => 1 ;

my $dump = DumpTree
			(
			\%hash,
			'hash_keys_sorter:',
			FILTER => CreateChainingFilter(\&no_sort_filter, \&hash_keys_sorter),
			) ;
			
my $expected_dump = <<EOD ;
hash_keys_sorter:
|- A = 1  [S1]
|- B = 1  [S2]
`- Z = 1  [S3]
EOD

is($dump, $expected_dump, 'hash_keys_sorter') ;
}

    
    
{
local $Plan = {'filter_class_keys' => 1} ;

package Vegetable ;

package Potatoe ;
our @ISA = ("Vegetable");

package BlueCongo;
our @ISA = ("Potatoe");

package main ;

my $data_1 = bless({ A => 1, B => 2, C => 3}, 'T1') ;
my $data_2 = bless({ A => 1, B => 2, C => 3}, 'T2') ;
my $data_3 = bless({ A => 1, B => 2, C => 3}, 'T3') ;
my $blue_congo = bless({IAM => 'A_BLUE_CONGO', COLOR => 'blue'}, 'BlueCongo') ;

my $dump = DumpTree
			(
			{D1 => $data_1, D2 => $data_2, D3 => $data_3, Z => $blue_congo,},
			'filter_class_keys:',

			FILTER => 
				CreateChainingFilter
					(
					filter_class_keys
						(
						# match class containing 'T1' in its name, show the 'A' key
						T1 => ['A'],

						# match T2 class, show all the key that don't contain 'C'
						qr/2/ => [qr/[^C]/], 

						# match any Potatoe, can't use a regex for class
						Potatoe => [qr/I/],

						# mach any hash or hash based object, displays all the keys
						'HASH' => [qr/./],
						),
						
					\&hash_keys_sorter
					),
			) ;
			
my $expected_dump = <<EOD ;
filter_class_keys:
|- D1 =  blessed in 'T1'  [OH1]
|  `- A = 1  [S2]
|- D2 =  blessed in 'T2'  [OH3]
|  |- A = 1  [S4]
|  `- B = 2  [S5]
|- D3 =  blessed in 'T3'  [OH6]
|  |- A = 1  [S7]
|  |- B = 2  [S8]
|  `- C = 3  [S9]
`- Z =  blessed in 'BlueCongo'  [OH10]
   `- IAM = A_BLUE_CONGO  [S11]
EOD

#~ use Text::Diff ;
is($dump, $expected_dump, 'filter_class_keys') ; #or diag (diff(\$dump, \$expected_dump)) ; 
}

{
local $Plan = {'get_caller_stack' => 1} ;


sub s1 { my $dump = eval {package xxx ; main::s2() ;} ; return $dump ; }
sub s2 { s3('a', [1, 2, 3]) ; }
sub s3 { DumpTree(get_caller_stack(), 'Stack dump:', DISPLAY_ADDRESS => 0) ; }
  
my $dump = s1() ;

my $expected_dump = <<EOD ;
Stack dump:
|- 0 
|  `- main::s1 
|     |- ARGS (no elements) 
|     |- AT = t/002_utils.t:259 
|     |- CALLERS_PACKAGE = main 
|     `- CONTEXT = scalar 
|- 1 
|  `- (eval) 
|     |- AT = t/002_utils.t:255 
|     |- CALLERS_PACKAGE = main 
|     |- CONTEXT = scalar 
|     `- EVAL = yes 
|- 2 
|  `- main::s2 
|     |- ARGS (no elements) 
|     |- AT = t/002_utils.t:255 
|     |- CALLERS_PACKAGE = xxx 
|     `- CONTEXT = scalar 
`- 3 
   `- main::s3 
      |- ARGS 
      |  |- 0 = a 
      |  `- 1 
      |     |- 0 = 1 
      |     |- 1 = 2 
      |     `- 2 = 3 
      |- AT = t/002_utils.t:256 
      |- CALLERS_PACKAGE = main 
      `- CONTEXT = scalar 
EOD

#~ use Text::Diff ;
is($dump, $expected_dump, 'filter_class_keys') ; #or diag (diff(\$dump, \$expected_dump)) ; 
}

