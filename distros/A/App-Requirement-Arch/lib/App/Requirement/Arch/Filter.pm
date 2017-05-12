
package App::Requirement::Arch::Filter ;

use strict ;
use warnings ;
use Data::Dumper;

use App::Requirement::Arch::Requirements 
		qw
		(
		get_requirements_structure 
		count_missing_elements
		show_abstraction_level
		)  ;

use App::Requirement::Arch::Categories qw(inherit_categories merge_and_check_master_category_definition) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(load_and_filter_requirements) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.01';
}

=head1 NAME

	App::Requirement::Arch::Filter - 

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=cut

sub load_and_filter_requirements
{
	
=head2 load_and_filter_requirements(...)

I<Arguments>

=over 2 

=item * $sources -

=item * $master_template_file -

=item * $master_category_definition_file -

=item * $show_abstraction_level -

=item * $remove_empty_requirement_field_in_categories -

=item * $include_not_found -

=item * $include_statistics -

=item * $include_description_data -

=item * $description_fields_to_keep -

=item * $display_multiline_as_array -

=item * $include_categories -

=item * $keep_types -

=back

I<Returns> - $requirements_structure, $requirements, $categories)

I<Exceptions>

See C<xxx>.

=cut


my
	(
	$sources,
	$master_template_file,
	$master_category_definition_file,
	$show_abstraction_level,
	$remove_empty_requirement_field_in_categories,
	$include_not_found,
	$include_statistics,
	$include_description_data,
	$description_fields_to_keep,
	$display_multiline_as_array,
	$include_categories,
	$keep_types,
	) = @_ ;
	
my ($requirements_structure, $requirements, $categories, $ok_parsed, $errors) = get_requirements_structure($sources, $master_template_file) ;

die "Error: Failed requirements parsing!" if $errors ;

for my $category_name (keys %{$categories})
	{
	delete $categories->{$category_name}{_FILES} ;
	delete $categories->{$category_name}{_ENTRIES} ;
	}

keep_requirements_of_type($categories, $requirements, $remove_empty_requirement_field_in_categories, $keep_types) ;
inherit_categories($requirements_structure, $requirements) ;
count_missing_elements($requirements_structure) ;
show_abstraction_level($requirements) if $show_abstraction_level ;
merge_and_check_master_category_definition($master_category_definition_file, $requirements_structure) ;

unless($include_not_found)
	{
	delete $requirements_structure->{NOT_FOUND} ;
	}
	
unless($include_statistics)
	{
	delete $requirements_structure->{STATISTICS} ;
	}

for my $requirement_name (keys %{$requirements})
	{
	delete $requirements->{$requirement_name}{DEFINED_AT} ;
	
	if($include_description_data)
		{
		if(exists $requirements->{$requirement_name}{DEFINITION})
			{
			my $requirements_definition = $requirements->{$requirement_name}{DEFINITION} ;
	
			for my $definition_key (keys %{$requirements_definition})
				{
				if(exists $description_fields_to_keep->{$definition_key})
					{
					if('' eq ref $requirements_definition->{$definition_key})
						{
						if($display_multiline_as_array)
							{
							$requirements_definition->{$definition_key} 
								= 
									[
									map {s/\t/   /; $_}
										split /\n/, $requirements_definition->{$definition_key}
									] ;
							}
						}
					}
				else
					{
					delete $requirements_definition->{$definition_key} ;
					}
				}
			}
		}
	else
		{
		delete $requirements->{$requirement_name}{DEFINITION} ;
		}

	if
		(
		! $include_categories
		|| ($requirements->{$requirement_name}{CATEGORIES} && @{$requirements->{$requirement_name}{CATEGORIES}} < 2)
		)
		{
		delete $requirements->{$requirement_name}{CATEGORIES} ;
		}
	}

return($requirements_structure, $requirements, $categories) ;
}

#--------------------------------------------------------------------------------------------------------------

sub keep_requirements_of_type
{

=head2 keep_requirements_of_type($categories, $requirements, $remove_empty_requirement_field_in_categories, $keep_types)

I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($categories, $requirements, $remove_empty_requirement_field_in_categories, $keep_types) = @_;

my %types_to_keep = map {$_ => 1} @{$keep_types} ;
my %requirements_to_delete ;
	
for my $requirement_name (keys %{$requirements})
	{
	if(exists $requirements->{$requirement_name}{DEFINITION} && exists $requirements->{$requirement_name}{DEFINITION}{TYPE})
		{
		unless(exists $types_to_keep{$requirements->{$requirement_name}{DEFINITION}{TYPE}})
			{
			$requirements_to_delete{$requirement_name}++ ;
			}
		}
	else
		{
		warn "Warning: Can't find requirement '$requirement_name' type (missing definition). Including it in the document!\n" ;
		}
	}

for my $category_name (keys %{$categories})
	{
	if(exists $categories->{$category_name}{_REQUIREMENTS})
		{
		for my $sub_requirement_name (keys %{$categories->{$category_name}{_REQUIREMENTS}})
			{
			if(exists $requirements_to_delete{$sub_requirement_name})
				{
				delete $categories->{$category_name}{_REQUIREMENTS}{$sub_requirement_name} ;
				}
			}
			
		if($remove_empty_requirement_field_in_categories)
			{
			delete $categories->{$category_name}{_REQUIREMENTS} unless keys %{$categories->{$category_name}{_REQUIREMENTS}} ;
			}
		}
	}

for my $requirement_name (keys %{$requirements})
	{
	if(exists $requirements->{$requirement_name}{SUB_REQUIREMENTS})
		{
		for my $sub_requirement_name (keys %{$requirements->{$requirement_name}{SUB_REQUIREMENTS}})
			{
			if(exists $requirements_to_delete{$sub_requirement_name})
				{
				delete $requirements->{$requirement_name}{SUB_REQUIREMENTS}{$sub_requirement_name} ;
				}
			}
		}
	}
	
for my $requirement_name (keys %requirements_to_delete)
	{
	delete $requirements->{$requirement_name} ;
	}
}

#-----------------------------------------------------------------------------------------

=head1 TO DO

=head1 SEE ALSO

=head1 AUTHOR

       Khemir Nadim ibn Hamouda.

=cut

#------------------------------------------------------------------------------------------------------------------

1 ;

