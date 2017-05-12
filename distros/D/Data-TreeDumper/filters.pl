#! /usr/bin/perl 

use strict ;
use warnings ;
use Carp ;

use Data::TreeDumper ;

our $s ;
do "s" ;

$Data::TreeDumper::Useascii = 1 ;

my $dump_separator = "\n" . '-' x 40 . "\n\n" ;

print DumpTree($s, 'Unaltered data structure') ;
print $dump_separator ;

#-------------------------------------------------------------------------------
# Level filters
#-------------------------------------------------------------------------------
sub GenerateFilter
{
my $letter = shift ;

return
	(
	sub
		{
		my $tree = shift ;
		
		if('HASH' eq ref $tree)
			{
			my @keys_to_dump ;
			for my $key_name (keys %$tree)
				{
				push @keys_to_dump, $key_name if($key_name =~ /^$letter/i)
				}
				
			return ('HASH', undef, @keys_to_dump) ;
			}
			
		return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
		}
	) ;
}

print DumpTree
	(
	$s
	, 'Level filters'
	, LEVEL_FILTERS =>
		{
		  0 => GenerateFilter('a')
		, 1 => GenerateFilter('b')
		, 2 => GenerateFilter('c')
		}
	) ;

print $dump_separator ;

#-------------------------------------------------------------------------------
# type filter
#-------------------------------------------------------------------------------

# this  is a constricted example but it serves its pupose
# all_entries_filter returns a an empty array for all the tree elements
# except the top element (the tree itself) or we wouldn't get any output
# We set the type filters for type 'SuperObject'. the filter overrides the global filter
# as it has higher priority

sub all_entries_filter
{
my ($tree, $level, $path, $nodes_to_display, $setup, $filter_argument) = @_ ;

return ('ARRAY', []) if $level != 0 ;

return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

print DumpTree
	(
	$s
	, 'type filters'
	, DISPLAY_TIE => 1
	, DISPLAY_NUMBER_OF_ELEMENTS => 1
	#~ , FILTER => \&all_entries_filter
	, TYPE_FILTERS =>
		{
		  Regexp =>
				sub
					{
					my $tree = shift ;
					return ('HASH', {THE_REGEXP=> "$tree"}, 'THE_REGEXP') ;
					}
		, SuperObject =>
				sub
					{
					my $tree = shift ;
					
					# while writting I got bitten as I thought all 'superObject's where hashes and I could
					# run keys %$tree on the object but the example data has a tied array which is also blessed
					# in 'SuperObjec'. So I had to add:  if("$tree" =~ /=HASH/ ) 
					
					if("$tree" =~ /=HASH/ )
						{
						my $number_of_keys  = my @keys = keys %$tree ;
						return ('HASH', {number_of_keys => $number_of_keys}, 'number_of_keys') ;
						}
						
					return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
					}
		, ARRAY =>
				sub
					{
					my $tree = shift ;
					return ('HASH', {ARRAY_FILTER => 1}, 'ARRAY_FILTER') ;
					}
		}
	) ;
	
print $dump_separator ;

#-------------------------------------------------------------------------------
# path filter
#-------------------------------------------------------------------------------

sub PathFilter
	{
	my ($tree, $level, $path, $nodes_to_display, $setup, $filter_argument) = @_ ;
	
	print "Filtering $tree at level: $level, path: $path\n" ;
	
	PrintTree $setup->{__PATH_ELEMENTS}, '__PATH_ELEMENTS', MAX_DEPTH => 2 ;
	
	return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
	}

print "Show the path a filter gets\n" ;
print DumpTree($s, "Tree", FILTER => \&PathFilter, NO_OUTPUT => 1) ;
print $dump_separator ;

#-------------------------------------------------------------------------------
# removing nodes from dump
#-------------------------------------------------------------------------------
sub RemoveAFromHash
{
# Entries matching /^a/i have '*' prepended

my $tree = shift ;

if('HASH' eq ref $tree)
	{
	my @keys_to_dump ;
	
	for my $key_name (keys %$tree)
		{
		push @keys_to_dump, $key_name unless($key_name =~ /^a/i)
		}
		
	return ('HASH', undef, @keys_to_dump) ;
	}
	
return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

print DumpTree($s, "Remove hash keys matching /^a/i", FILTER => \&RemoveAFromHash) ;
print $dump_separator ;

#-------------------------------------------------------------------------------
# label changing
#-------------------------------------------------------------------------------

sub StarOnA
{
# Entries matching /^a/i have '*' prepended

my $tree = shift ;

if('HASH' eq ref $tree)
	{
	my @keys_to_dump ;
	
	for my $key_name (keys %$tree)
		{
		if($key_name =~ /^a/i)
			{
			$key_name = [$key_name, "* $key_name"] ;
			}
			
		push @keys_to_dump, $key_name ;
		}
		
	return ('HASH', undef, @keys_to_dump) ;
	}
	
return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

print DumpTree($s, "Entries matching /^a/i have '*' prepended", FILTER => \&StarOnA) ;
print $dump_separator ;

#-------------------------------------------------------------------------------
# level numbering and tagging
#-------------------------------------------------------------------------------

print DumpTree($s, "Level numbering", NUMBER_LEVELS => 2) ;
print $dump_separator ;

sub GetLevelTagger
{
my $level_to_tag = shift ;

sub 
	{
	my ($tree, $level, $path, $nodes_to_display, $setup) = @_ ;
	
	my $tag = "Level $level_to_tag: ";
	
	if($level == 0) 
		{
		return($tag) ;
		}
	else
		{
		return(' ' x length($tag)) ;
		}
	} ;
}

print DumpTree($s, "Level tagging", NUMBER_LEVELS => GetLevelTagger(0)) ;
print $dump_separator ;

#-------------------------------------------------------------------------------
# Coloring : see examples in color.pl
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Glyphs, color and key quoting
#-------------------------------------------------------------------------------
print DumpTree
	(
	$s, "Glyphs and key quoting"
	, GLYPHS => ['.  ', '.  ', '.  ', '.  ']
	, QUOTE_HASH_KEYS => 1
	) ;

#-------------------------------------------------------------------------------
# tree replacement
#-------------------------------------------------------------------------------

sub MungeArray
{
my $tree = shift ;

if('ARRAY' eq ref $tree)
	{
	my $concatenation = '' ;
	$concatenation .= $_ for (@$tree) ;
	
	return ('ARRAY', [$concatenation ], [0, 'concatenation of all the values']) ;
	}
	
return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

print DumpTree($s, 'MungeArray!', FILTER => \&MungeArray) ;
print $dump_separator ;

sub ReplaceArray
{
# replace arrays with hashes!!!

my $tree = shift ;

if('ARRAY' eq ref $tree)
	{
	my $replacement = {OLD_TYPE => 'Array', NEW_TYPE => 'Hash'} ;
	return ('HASH', $replacement, keys %$replacement) ;
	}
	
return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

print DumpTree($s, 'Replace arrays with hashes!', FILTER => \&ReplaceArray) ;
print $dump_separator ;

#-------------------------------------------------------------------------------
# filter chaining
#-------------------------------------------------------------------------------

sub AddStar
{
my $tree = shift ;
my $level = shift ;
my $path = shift ;
my $keys = shift ;

if('HASH' eq ref $tree)
	{
	$keys = [keys %$tree] unless defined $keys ;
	
	my @new_keys ;
	
	for (@$keys)
		{
		if('' eq ref $_)
			{
			push @new_keys, [$_, "* $_"] ;
			}
		else
			{
			# another filter has changed the label
			push @new_keys, [$_->[0], "* $_->[1]"] ;
			}
		}
	
	return('HASH', undef, @new_keys) ;
	}
	
return(Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

sub RemoveA
{
my $tree = shift ;
my $level = shift ;
my $path = shift ;
my $keys = shift ;

if('HASH' eq ref $tree)
	{
	$keys = [keys %$tree] unless defined $keys ;
	my @new_keys ;
	
	for (@$keys)
		{
		if('' eq ref $_)
			{
			push @new_keys, $_ unless /^a/i ;
			}
		else
			{
			# another filter has changed the label
			push @new_keys, $_ unless $_->[0] =~ /^a/i ;
			}
		}
	
	return('HASH', undef, @new_keys) ;
	}
	
return(Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
}

print DumpTree($s, 'AddStar', FILTER => \&AddStar) ;
print $dump_separator ;

print DumpTree($s, 'RemoveA', FILTER => \&RemoveA) ;
print $dump_separator ;

print DumpTree($s, 'AddStart + RemoveA', FILTER => CreateChainingFilter(\&AddStar, \&RemoveA)) ;
print $dump_separator ;
