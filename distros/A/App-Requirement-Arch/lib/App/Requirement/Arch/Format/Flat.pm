
package App::Requirement::Arch::Format::Flat ;

use strict ;
use warnings ;
use Data::Dumper;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(generate_flat_document_structure) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.01';
}


=head1 NAME

	App::Requirement::Arch::Format::Flat - Transform the standard requirement structure to a "flat" one.

=head1 SYNOPSIS

	use App::Requirements::Arch::Filter ;
	use App::Requirements::Arch::Format::Flat ;
	
	my ($requirements_structure, $requirements, $categories) 
		= load_and_filter_requirements( ...) ;

	keep_abstraction_level_requirements($requirements, @keep_abstraction_level) ;
	
	my $flat_document_structure = generate_flat_document_structure($requirements);

=head1 DESCRIPTION

This module provides functionality to generate a 'flat' (as opossed to the hierarchical structure used when developing
requirements) requirements structure that can be used to generate document intended for users that need 'less'
complicated requirement visualisation. See B<ra_show_flat>.

=head1 SUBROUTINES/METHODS

=cut

#-----------------------------------------------------------------------------------------

sub generate_flat_document_structure
{
	
=head2 generate_flat_document_structure(\%requirements)

Loads requirements and sorts them generating a document structure based on the B<top category> of the 
requirements.

I<Arguments>

=over 2

=item * \%requirements - The structured requirement.

=back

I<Returns> 

=over 2

=item * %flat_document_structure - A reference to a structure to be used to generate the flat document

=back

=cut

my ($requirements) = @_;

my $flat_document_structure = {} ;

# sort the requirements according to their abstraction level
for my $requirement_name (keys %{$requirements})
	{
	if(exists $requirements->{$requirement_name}{DEFINITION})
		{
		my $requirement_definition = $requirements->{$requirement_name}{DEFINITION} ;
		
		if(exists $requirement_definition->{ABSTRACTION_LEVEL}) 
			{
			my $level = $requirement_definition->{ABSTRACTION_LEVEL} ;
		
			if(defined $requirement_definition->{CATEGORIES} && @{$requirement_definition->{CATEGORIES}})
				{
				for my $category (@{$requirement_definition->{CATEGORIES}})
					{
					$category =~ s/ \(inherited from:.*\)// ; # remove where the category is inherited from
					
					($category) = $category =~ m/^([^\/]+)/ ; # this changes the category in the requirement
					$flat_document_structure->{CATEGORY_SORT}{$category}{$level}{$requirement_name} = $requirements->{$requirement_name};
					}
				}
			else
				{
				$flat_document_structure->{CATEGORY_SORT}{NO_CATEGORY}{$level}{$requirement_name} = $requirements->{$requirement_name};
				}
			}
		# else
			# only requirements with with an abstraction level make it into the document
		}
	# else
		# only requirements with with an abstraction level defined make it into the document
	}

return ($flat_document_structure);
}

#-----------------------------------------------------------------------------------------

=head1 SEE ALSO

=head1 AUTHOR

     Khemir Nadim ibn Hamouda.
     Ian Kumlien

=cut

#------------------------------------------------------------------------------------------------------------------

1 ;

