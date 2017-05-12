#! /usr/bin/perl

use strict ;
use warnings ;
use Carp ;

use Data::TreeDumper ;
use Data::TreeDumper::OO ;

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
		, eeeee => $sub
		, f => $sub
		, g => $sub
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
	, B => 'scalar'
	, C => [qw(element_1 element_2)]
	, HASH =>
		{
		a => 'a',
		1 => 1,
		'1a' => 1,
		2 => 2,
		9 => 9,
		10 => 10,
		11 => 11,
		19 => 19,
		20 => 20,
		'2b' => '2b',
		'2b0' => '2b0',
		'20b' => '20b',
		}
	) ;

my $hi = '25' ;
my $array_ref = [0, 1, \$hi] ;
$tree{Nadim} = \$array_ref ;
#~ $tree{REF2_to_array_ref} = \$array_ref ;

#~ $tree{aREF_to_C} = $tree{C} ;
#~ $tree{REF_to_C} = \($tree{C}) ;

#~ $tree{aREF_REF_to_C} = $tree{REF_to_C} ;
#~ $tree{REF_REF_to_C} = \($tree{REF_to_C}) ;

$tree{SELF} = [ 0, 1, 2, \%tree] ;
$tree{RREF} = \\$array_ref ;
$tree{RREF2} = \\$array_ref ;

$tree{SCALAR} = \$hi ;
$tree{SCALAR2} = \$hi ;
$tree{ARRAY} = [0, 1, \$hi] ;

my $object = {m1 => 12, m2 => [0, 1, 2]} ;
bless $object, 'SuperObject' ;

$tree{OBJECT} = $object ;
$tree{OBJECT2} = $object ;
$tree{OBJECT_REF_REF_REF} = \\\$object ;

my $ln = 'Long_name ' x 20 ;
$tree{$ln} = 0 ;

$tree{ARRAY2} = [0, 1, \$object, $object] ;

use IO::File;
my $fh = new IO::File;
$tree{FILE} = $fh ;

use IO::Handle;
my $io = new IO::Handle;

$tree{IO} = $io ;

$tree{ARRAY_ZERO} = [] ;

sub HashKeysStartingAboveA
{
my $tree = shift ;

if('HASH' eq ref $tree)
	{
	return( 'HASH', undef, sort grep {!/^A/} keys %$tree) ;
	}
	
return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

my $tree_dumper = new Data::TreeDumper::OO ;
#~ $tree_dumper->UseAnsi(1) ;
#~ $tree_dumper->UseAscii(0) ;
#~ $tree_dumper->SetMaxDepth(2) ;

print $tree_dumper->Dump(\%tree, "Data:TreeDumper dump example:",  DISPLAY_ROOT_ADDRESS => 1, DISPLAY_PERL_SIZE => 0, USE_ASCII => 0) ;

use Data::Dumper;
print Dumper \%tree ;

print $tree_dumper->Dump(\%tree, "Data:TreeDumper dump example:", MAX_DEPTH => 1, DISPLAY_NUMBER_OF_ELEMENTS_OVER_MAX_DEPTH => 1) ;

