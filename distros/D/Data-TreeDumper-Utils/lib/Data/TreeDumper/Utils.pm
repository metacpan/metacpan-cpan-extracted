
package Data::TreeDumper::Utils ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(first_nsort_last_filter keys_order no_sort_filter hash_keys_sorter filter_class_keys get_caller_stack) ],
	groups  => 
		{
		all  => [ qw(first_nsort_last_filter keys_order no_sort_filter hash_keys_sorter filter_class_keys get_caller_stack) ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.04';
}

#-------------------------------------------------------------------------------

use Sort::Naturally;
use Check::ISA ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::TreeDumper::Utils - A selection of utilities to use with Data::TreeDumper

=head1 SYNOPSIS

  use Data::TreeDumper::Utils qw(:all) ;
  
  DumpTree
    (
    $requirements_structure,
    'Requirements structure:',
    FILTER => \&first_nsort_last_filter,
    FILTER_ARGUMENT => {...},
    ) ;
  
  DumpTree #shorthand for the call to first_nsort_last_filter
    (
    $requirements_structure,
    'Requirements structure:',
    keys_order(...),
    ) ;
  
  DumpTree
    (
    $ixhash_hash_ref,
    'An IxHash hash',
    FILTER => \&no_sort_filter,
    ) ;
  
  DumpTree
    (
    $structure,
    'sorted',
    FILTER => 
      CreateChainingFilter
      (
      \&remove_keys_starting_with_A,
      \&hash_keys_sorter
      ),
    ) ;
  
  DumpTree
    (
    $structure,
    'filter_class_keys example:',
    FILTER => filter_class_keys(T1 => ['A'], 'HASH' => [qr/./],),
    ) ;
  
  DumpTree(get_caller_stack(), 'Stack dump:') ;

=head1 DESCRIPTION

A collection useful sorting filters and utilities that can be used with L<Data::TreeDumper>. You can also
study the source for examples of how to write filters.

=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------------

sub first_nsort_last_filter ## no critic Subroutines::ProhibitManyArgs
{

=head2 first_nsort_last_filter()

This filter will apply to all hashes and object derived from hashes, it allows you to change the order in
which the keys are rendered.

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

generates:
  structure:
  |- ZZZ = 1  [S1]
  |- B = 1  [S2]
  |- B2 = 1  [S3]
  |- D = 1  [S4]
  |- E = 1  [S5]
  |- A = 1  [S6]
  |- C = 1  [S7]
  `- AXC = 1  [S8]

B<Arguments>

The arguments are passed through the call to L<Data::TreeDumper> in the B<FILTER_ARGUMENT>
option. B<FILTER_ARGUMENT> points to a hash reference with the possible following keys. All the keys are optional.

Each key is an array reference containing a list of regexes or strings. Keys matching the regexes or string will be 
sorted in the category in which the matching regex or string was declared. The categories are, in priority order:

=over 2 

=item * REMOVE - the keys that should not be rendered

=item * AT_START_FIXED - the keys that should be rendered at the start, will not be sorted

=item * AT_START - the keys that should be rendered next, will be sorted

=item * AT_END - the keys that should be rendered last, will be sorted

=item * AT_END_FIXED - the keys that should be rendered at the end, will not be sorted

=back

Any key that doesn't match a regex or a string will automatically be in this category.

Keys are sorted by L<Sort::Naturally>.

B<Returns> - the keys sorted according to the defined categories.

B<See> - I<Filters> in L<Data::TreeDumper>.

=cut

my ($structure, undef, undef, $nodes_to_display, undef, $filter_argument) = @_ ;

if('HASH' eq ref $structure || obj($structure, 'HASH'))
	{
	my $keys = defined $nodes_to_display ? $nodes_to_display : [keys %{$structure}] ;
	return
		(
		'HASH',
		undef,
		first_nsort_last
			(
			%{$filter_argument}, 
			KEYS => $keys,
			)  
		) ;
	}
	
return(Data::TreeDumper::DefaultNodesToDisplay($structure)) ;
}

sub keys_order
{

=head2 keys_order(@filtering_categories)ma

See L<first_nsort_last_filter()>

  DumpTree($structure, 'title:', keys_order(REMOVE => [], AT_START => [], ...)) ;
  
=cut

return
	FILTER => \&first_nsort_last_filter,
	FILTER_ARGUMENT => { @_ } ;
}

sub first_nsort_last
{

=head2 [p] first_nsort_last(AT_START => [regex, string, ...], AT_END => [regex, string, ...], ..., KEYS => [keys to sort] )

Implementation of I<first_nsort_last_filter> key sorting.

B<Arguments>

=over 2 

=item * REMOVE - a reference to an array containing regexes or strings, keys matching will be removed from display

=item * AT_START_FIXED - a reference to an array containing regexes or strings, won't be sorted, multiple matches to regex are sorted

=item * AT_START - a reference to an array containing regexes or strings, will be sorted

=item * AT_END - a reference to an array containing regexes or strings, will be sorted

=item * AT_END_FIXED - a reference to an array containing regexes or strings, won't be sorted

=item * KEYS - a reference to an array containing the keys to sort

=back

B<Returns> - the sorted keys

=cut

my (%argument_hash) = @_ ;

my @keys =@{ $argument_hash{KEYS} || []} ;
 
if(exists $argument_hash{REMOVE})
	{
	my @remove_regex = map { {regexp => $_} }  @{ $argument_hash{REMOVE}} ;
	@keys = grep {! match_regexes($_, @remove_regex)} @keys ;
	}


my @at_start_fixed = map { {regexp => $_} }  @{ $argument_hash{AT_START_FIXED} } if exists $argument_hash{AT_START_FIXED} ;

my $at_start_matches = [] ; #all the matches must be in the same array so we can do an nsort on them
my @at_start = map { {regexp => $_, matches => $at_start_matches } } @{ $argument_hash{AT_START} } if exists $argument_hash{AT_START} ;

my $at_end_matches = [] ;
my @at_end = map { {regexp => $_, matches => $at_end_matches } } @{ $argument_hash{AT_END} } if exists $argument_hash{AT_END} ;

my @at_end_fixed = map { {regexp => $_} }  @{ $argument_hash{AT_END_FIXED} } if exists $argument_hash{AT_END_FIXED} ;

my @in_the_middle = {regexp => qr//} ; # matches everything that the other have not

match_regexes($_, @at_start_fixed, @at_start, @at_end, @at_end_fixed, @in_the_middle) for(@keys) ;

return
	map
		{
		exists $_->{matches} ?
			nsort( @{ $_->{matches} } )  :
			() ;
		}
		@at_start_fixed, { matches => $at_start_matches }, @in_the_middle, { matches => $at_end_matches }, @at_end_fixed ;	
}


sub match_regexes
{
=head2 [p] match_regexes($key, @regexes)

matches the key to a set of filterring regexps

B<Arguments>

=over 2 

=item * $key - a string, the hash key to be matched to the sorting regexes

=item * @regexes - an array, each element contains a Regexp or a stig to match to I<$key>, matches are added to the regexp element

=back

B<Returns> - the sorted keys

=cut

my ($key, @regexes) = @_ ;

my $match ;

for my $regexp (@regexes)
	{
	if('Regexp' eq ref $regexp->{regexp})
		{
		if ($key =~ $regexp->{regexp})
			{
			push @{ $regexp->{matches} }, $key ;
			$match++ ;
			last ;
			}
		}
	else
		{
		if ($key eq $regexp->{regexp})
			{
			push @{ $regexp->{matches} }, $key ;
			$match++ ;
			last ;
			}
		}
	}
	
return $match ;
}

#-------------------------------------------------------------------------------

sub  no_sort_filter
{

=head2 no_sort_filter()

A hash filter to replace the default L<Data::TreeDumper> filter which sorts hash keys. This is useful if you have a 
hash based on L<Tie::IxHash>, or equivalent, that keep the key order internally.

  print DumpTree
    (
    $ixhash_hash_ref,
    'An IxHash hash',
    FILTER => \&no_sort_filter,
    ) ;

B<Arguments> - none

B<Returns> - hash keys unsorted

=cut

my ($structure, undef, undef, $keys) = @_ ;

if('HASH' eq ref $structure|| obj($_, 'HASH'))
	{
	return('HASH', undef, @{$keys}) if(defined $keys) ;
	return('HASH', undef, keys %{$structure}) ;
	}
else
	{
	return Data::TreeDumper::DefaultNodesToDisplay(@_) ;
	}
}

#-------------------------------------------------------------------------------

sub hash_keys_sorter
{

=head2 hash_keys_sorter()

When no filter is given to L<Data::TreeDumper>, it will sort hash keys using L<Sort::Naturally>. If you create your
own filter or have chaining filters, you will have to do the sorting yourself (if you want keys to be sorted) or you can
use this filter to do the sorting.

  # Remove keys starting with A, return in keys in the order the hash returns them
  DumpTree($s, 'not sorted', FILTER => \&remove_keys_starting_with_A,) ;
  
  # Remove keys starting with A, sort keys
  DumpTree
    (
    $s,
    'sorted',
    FILTER => CreateChainingFilter(\&remove_keys_starting_with_A, \&hash_keys_sorter),
    ) ;
	

B<Arguments> - none

B<Returns> - the sorted keys

=cut

my ($structure, undef, undef, $nodes_to_display) = @_ ;

if('HASH' eq ref $structure || obj($structure, 'HASH'))
	{
	my $keys = defined $nodes_to_display ? $nodes_to_display : [keys %{$structure}] ;
	
	my %keys ;
	
	for my $key (@{$keys})
		{
		if('ARRAY' eq ref $key)
			{
			$keys{$key->[0]} = $key ;
			}
		else
			{
			$keys{$key} = $key ;
			}
		}
		
	return('HASH', undef, map{$keys{$_}} nsort keys %keys) ;
	}

return(Data::TreeDumper::DefaultNodesToDisplay($structure)) ;
}

#----------------------------------------------------------------------

sub filter_class_keys
{

=head2 filter_class_keys($class => \@keys,  $class => \@keys,,  ...)

A filter that allows you select which keys to render depending on the type of the structure elements. This lets you
filter out data you don't want to render.

Note: this filter does not sort the keys!

  package Potatoe ;
  
  package BlueCongo;
  @ISA = ("Potatoe");
  
  package main ;
  
  use strict ;
  use warnings ;
  
  use Data::TreeDumper ;
  
  my $data_1 = bless({ A => 1, B => 2, C => 3}, 'T1') ;
  my $data_2 = bless({ A => 1, B => 2, C => 3}, 'T2') ;
  my $data_3 = bless({ A => 1, B => 2, C => 3}, 'T3') ;
  my $blue_congo = bless({IAM => 'A_BLUE_CONGO', COLOR => 'blue'}, 'BlueCongo') ;
  
  print DumpTree
    (
    {D1 => $data_1, D2 => $data_2, D3 => $data_3, Z => $blue_congo,},
    'filter_class_keys example:',
    
    FILTER => filter_class_keys
      (
      # match class containing 'T1' in its name, show the 'A' key
      T1 => ['A'],
      
      # match T2 class, show all the key that don't contain 'C'
      qr/2/ => [qr/[^C]/], 
	
      # match BlueCongo class via regex
      # qr/congo/i => [qr/I/],
      
      # match BlueCongo class
      # BlueCongo => [qr/I/], 
      
      # match any Potatoe, can't use a regex for class
      Potatoe => [qr/I/],
    
      # mach any hash or hash based object, displays all the keys
      'HASH' => [qr/./],
      ),
    ) ;

generates:

  filter_class_keys example:
  |- Z =  blessed in 'BlueCongo'  [OH1]
  |  `- IAM = A_BLUE_CONGO  [S2]
  |- D2 =  blessed in 'T2'  [OH3]
  |  |- A = 1  [S4]
  |  `- B = 2  [S5]
  |- D3 =  blessed in 'T3'  [OH6]
  |  |- A = 1  [S7]
  |  |- C = 3  [S8]
  |  `- B = 2  [S9]
  `- D1 =  blessed in 'T1'  [OH10]
     `- A = 1  [S11]    

B<Arguments> 

A list of:

=over 2 

=item * $class - either a regex or a string.

=item * \@keys - a reference to an array containing the keys to display. The keys can be a string or a regex.

=back

B<Returns> - the keys to render

=cut

my (@class_to_key) = @_ ;
my @classes ;

for(my $index = 0 ; $index < $#class_to_key ; $index += 2) ## no critic ControlStructures::ProhibitCStyleForLoops 
	{
	croak 'class must be a string or a regex!' unless $EMPTY_STRING eq ref $class_to_key[$index] || 'Regexp' eq ref $class_to_key[$index] ;
	croak 'keys must be passed in an array reference!' unless 'ARRAY' eq ref $class_to_key[$index + 1] ;
	
	my @regexes = @{$class_to_key[$index + 1]} ;
	
	push @classes, 
		[
		$class_to_key[$index],
		sub
			{
			my ($value) = @_ ;
			
			for my $regex (@regexes)
				{
				return 1 if $value =~ $regex ;
				}
				
			return 0 ;
			},
		] ;
	}

return sub
	{
	my ($s) = @_ ;
	my $ref_s =  ref $s  ;
	
	if($ref_s eq 'HASH' || obj($s, 'HASH'))
		{
		for my $class (@classes)
			{
			if($ref_s =~ $class->[0] || obj($s, $class->[0]))
				{
				return('HASH', undef, grep {$class->[1]->($_)} keys %{$s}) ;
				}
			}
			
		return('HASH', {},) ;
		}
	else
		{
		return(Data::TreeDumper::DefaultNodesToDisplay($s)) ;
		}
        } ;
}

#-------------------------------------------------------------------------------

sub get_caller_stack
{

=head2 get_caller_stack($levels_to_dump)

Creates a data structure containing information about the call stack.

  s1() ;
  
  sub s1 { my $x = eval {package xxx ; main::s2() ;} ; }
  sub s2 { s3('a', [1, 2, 3]) ; }
  sub s3 { print DumpTree(get_caller_stack(), 'Stack dump:') ; }
  
  will generate this stack dump:
  
  Stack dump:
  |- 0 
  |  `- main::s1 
  |     |- ARGS (no elements) 
  |     |- AT = try_me.pl:20 
  |     |- CALLERS_PACKAGE = main 
  |     `- CONTEXT = void 
  |- 1 
  |  `- (eval) 
  |     |- AT = try_me.pl:24 
  |     |- CALLERS_PACKAGE = main 
  |     |- CONTEXT = scalar 
  |     `- EVAL = yes 
  |- 2 
  |  `- main::s2 
  |     |- ARGS (no elements) 
  |     |- AT = try_me.pl:24 
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
        |- AT = try_me.pl:29 
        |- CALLERS_PACKAGE = main 
        `- CONTEXT = scalar 
        

B<Arguments>

=over 2 

=item * $levels_to_dump - the number of level that should be included in the call stack

=back

B<Returns> - the call stack structure

=cut

my $level_to_dump = shift || 1_000_000 ; ## no critic ValuesAndExpressions::ProhibitMagicNumbers
my $current_level = 2 ; # skip this function 

$level_to_dump += $current_level ; #

my @stack_dump ;

while ($current_level < $level_to_dump) 
	{
	my  ($package, $filename, $line, $subroutine, $has_args, $wantarray,
	    $evaltext, $is_require, $hints, $bitmask) = eval " package DB ; caller($current_level) ;" ;  ## no critic BuiltinFunctions::ProhibitStringyEval
	    
	last unless defined $package;
	
	my %stack ;
	$stack{$subroutine}{EVAL}            = 'yes'       if($subroutine eq '(eval)') ;
	$stack{$subroutine}{EVAL}            = $evaltext   if defined $evaltext ;
	$stack{$subroutine}{ARGS}            = [@DB::args] if($has_args) ; ## no critic Variables::ProhibitPackageVars
	$stack{$subroutine}{'REQUIRE-USE'}   = 'yes'       if $is_require ;
	$stack{$subroutine}{CONTEXT}         = defined $wantarray ? $wantarray ? 'list' : 'scalar' : 'void' ;
	$stack{$subroutine}{CALLERS_PACKAGE} = $package ;
	$stack{$subroutine}{AT}              = "$filename:$line" ;
	
	unshift @stack_dump, \%stack ;
	$current_level++;
	}

return(\@stack_dump);
}

#---------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NH
	mailto: nadim@cpan.org

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::TreeDumper::Utils

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-TreeDumper-Utils>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-data-treedumper-utils@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Data-TreeDumper-Utils>

=back

=head1 SEE ALSO

=cut
