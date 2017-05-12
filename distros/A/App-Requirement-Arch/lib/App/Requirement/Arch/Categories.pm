#!/usr/bin/perl

package App::Requirement::Arch::Categories ;

use strict ;
use warnings ;
use Data::Dumper;
use File::Find::Rule ;
use Data::TreeDumper ;
use Text::Pluralize ;
use Data::Compare ;
use Readonly ;
use Tie::IxHash ;

use App::Requirement::Arch qw(load_master_categories) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(inherit_categories merge_and_check_master_category_definition merge_master_categories) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};

use vars qw ($VERSION);
$VERSION     = '0.01';
}

#--------------------------------------------------------------------------------------------------------------

use Memoize qw(memoize flush_cache) ;
memoize('get_categories');

sub inherit_categories
{
	
=head2 inherit_categories()


I<Arguments>

=over 2

=item * 

=item * 

=item * 

=back

I<Returns> 

=over 2

=item *  - 

=back

=cut

my ($requirements_structure, $requirements) = @_ ;

flush_cache('get_categories') ;

for my $requirement (values %{$requirements})
	{
	if(exists $requirement->{SUB_REQUIREMENTS})
		{
		for my $sub_requirement_name (keys %{$requirement->{SUB_REQUIREMENTS}})
			{
			my $sub_requirement = $requirement->{SUB_REQUIREMENTS}{$sub_requirement_name} ;
			push @{$sub_requirement->{PARENTS}}, $requirement ;
			}
		}
	}

for my $requirement_name (keys %{$requirements})
	{
	my $requirement = $requirements->{$requirement_name} ;
		
	my @inherited_categories =  get_categories($requirement, 0) ;
	$requirement->{CATEGORIES} = [@inherited_categories] if @inherited_categories ;
	
	if (exists $requirement->{DEFINITION} and exists $requirement->{DEFINITION}{CATEGORIES} and  scalar(@{$requirement->{DEFINITION}{CATEGORIES}}))
		{
		push @{$requirement->{CATEGORIES}}, @{$requirement->{DEFINITION}{CATEGORIES}};
		}
		
	if (exists $requirement->{CATEGORIES} and  scalar(@{$requirement->{CATEGORIES}}))
		{
		delete $requirements_structure->{'NOT_CATEGORIZED'}{_REQUIREMENTS}{$requirement_name} ;
		}
	}

for my $requirement_name (keys %{$requirements})
	{
	delete $requirements->{$requirement_name}{PARENTS} ;
	}
}

#-------------------------------------------------------------------------------

sub get_categories
{

=head2 get_categories()


I<Arguments>

=over 2

=item * 

=item * 

=item * 

=back

I<Returns> 

=over 2

=item *  - 

=back

=cut

my ($requirement, $level) = @_ ;

my @categories ;

if(exists $requirement->{PARENTS})
	{
	for my $parent (@{$requirement->{PARENTS}})
		{
		push @categories,  get_categories($parent, $level + 1) ;
		}
	}

if ($level > 0 and exists $requirement->{DEFINITION}{CATEGORIES} and  scalar(@{$requirement->{DEFINITION}{CATEGORIES}}))
	{
	push @categories, map{"$_ (inherited from: $requirement->{DEFINITION}{NAME})"} @{$requirement->{DEFINITION}{CATEGORIES}}  ;
	}
	
return @categories ;
}
	
#-------------------------------------------------------------------------------

sub merge_and_check_master_category_definition
{

=head2 merge_and_check_master_category_definition($master_category_definition_file, $requirements_structure)

I<Arguments>

=over 2

=item * 

=item * 

=item * 

=back

I<Returns> 

=over 2

=item *  - 

=back

=cut

my ($master_category_definition_file, $requirements_structure) = @_ ;

my $category_structure = load_master_categories($master_category_definition_file) ;

my ($in_master_only, $in_requirements_only) = merge_master_categories($category_structure, $requirements_structure, '') ;

if(keys %{$in_master_only})
	{
	warn "Categories in the master categories but not in the requirements:\n" ;
	warn "\t$_\n" for (sort keys %{$in_master_only}) ;
	}
	
if(keys %{$in_requirements_only})
	{
	warn "Categories in requirements but not in the master categories:\n" ;
	warn "\t$_\n" for (sort keys %{$in_requirements_only}) ;
	}
} 

#-------------------------------------------------------------------------------

sub merge_master_categories
{

=head2 merge_master_categories($category_structure, $requirements_structure, $root)


I<Arguments>

=over 2

=item * 

=item * 

=item * 

=back

I<Returns> 

=over 2

=item *  - 

=back

=cut

my ($category_structure, $requirements_structure, $root) = @_ ;	

my (%in_master_only, %in_requirements_only) ;

for my $category (grep {! /^_/}  keys %{$category_structure})
	{
	if(exists $requirements_structure->{$category})
		{
		my ($in_master_only, $in_requirements_only)
			= merge_master_categories($category_structure->{$category}, $requirements_structure->{$category}, "$root/$category") ;
			
		%in_master_only = (%in_master_only, %{$in_master_only});
		%in_requirements_only = (%in_requirements_only, %{$in_requirements_only}) ;
		}
	else
		{
		$in_master_only{"$root/$category"}++ ;
		$requirements_structure->{$category} = '_IN_MASTER_CATEGORIES_ONLY' ;
		}
	}

for my $requirement_category (grep {! /^_/}  keys %{$requirements_structure})
	{
	unless (exists $category_structure->{$requirement_category})
		{
		$in_requirements_only{"$root/$requirement_category"}++ ;
		$requirements_structure->{$requirement_category}{_DOES_NOT_EXIST_IN_THE_MASTER_CATEGORIES}++ ;
		}
	}

return (\%in_master_only, \%in_requirements_only) ;
}

#-------------------------------------------------------------------------------------------------------------------

1 ;

