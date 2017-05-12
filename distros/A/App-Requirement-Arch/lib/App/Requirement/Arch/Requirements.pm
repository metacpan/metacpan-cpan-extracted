
package App::Requirement::Arch::Requirements ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw
				(
				check_requirements
				get_requirements_violations				
				get_files_to_check 
				load_requirement 
				create_requirement 
				get_requirements_structure
				count_missing_elements
				show_abstraction_level
				) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.01';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use File::Find::Rule ;
use Data::TreeDumper ;
use Text::Pluralize ;
use Data::Compare ;
use Readonly ;
use Tie::IxHash ;

use App::Requirement::Arch qw(get_template_files load_master_template) ;

#-------------------------------------------------------------------------------

=head1 NAME

=head1 SYNOPSIS

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

=cut

#--------------------------------------------------------------------------------------------------------------

sub get_requirements_structure
{

=head2 get_requirements_structure( \@sources, $master_template_file )

I<Arguments>

=over 2 

=item * $sources -

=item * $master_template_file -

=back

I<Returns> - $requirements_structure, $requirements, $categories, $ok_parsed, $error

I<Exceptions>

See C<xxx>.

=cut

my ($sources, $master_template_file) = @_ ;

my $master_template = load_master_template($master_template_file) ;

my ($ok_parsed, $errors, $entries_with_wrong_type, $requirements_structure, $categories, $requirements) = (0, 0, 0, {}, {}, {}) ;

for my $file (get_files_to_check($sources))
	{
	(my $requirement) = load_requirement($master_template, $file) ;
	
	unless (defined $requirement)
		{
		$errors++ ;
		next ; 
		} 
	
	unless($requirement->{TYPE} eq 'requirement')
		{
		warn "Warning: Ignoring '$requirement->{NAME}' with type '$requirement->{TYPE}'\n" ;
		$entries_with_wrong_type++ ;
		next ;
		}

	$ok_parsed++ ;
	
	my $requirement_name = $requirement->{NAME} ;
	
	# check if requirement is unique
	if(exists $requirements->{$requirement_name})
		{
		croak <<EOE if exists $requirements->{$requirement_name}{DEFINED_AT} ;
Error: requirement '$requirement_name' is defined in multiple files:
	$file 
	$requirements->{$requirement_name}{DEFINED_AT}
EOE
		# this requirement existed because someone refered to it before we parsed its defintion
		$requirements->{$requirement_name}{DEFINITION} = $requirement ;
		$requirements->{$requirement_name}{DEFINED_AT} = $file ;
		}
	else
		{
		$requirements->{$requirement_name} = {DEFINITION => $requirement, DEFINED_AT => $file} ;
		}

	my $current_requirement = $requirements->{$requirement_name} ;
	
	delete $current_requirement->{DEFINITION_IS_MISSING} ;
	delete $current_requirement->{CREATED_AT} ;
	
	# handle sub requirement definitions
	for my $sub_requirement_name (@{$requirement->{SUB_REQUIREMENTS}})
		{
		my $sub_requirement ;
		
		if(exists $requirements->{$sub_requirement_name})
			{
			$sub_requirement = $requirements->{$sub_requirement_name} ;
			}
		else
			{
			$sub_requirement =  {DEFINITION_IS_MISSING => 1, CREATED_AT => $file} ;
			$requirements->{$sub_requirement_name} =  $sub_requirement  ;
			}
			
		$current_requirement->{SUB_REQUIREMENTS}{$sub_requirement_name} =  $sub_requirement ;
		}
	
	# handle categorization, note that category inheritance is handle by a different sub
	if (@{$requirement->{CATEGORIES}})
		{
		for my $category (@{$requirement->{CATEGORIES}})
			{
			my $current_category = $requirements_structure ;
			$category =~ s/^\/// ;
			
			for my $category_path (split '/', $category)
				{
				$current_category->{$category_path} = {} unless exists $current_category->{$category_path} ;
				$current_category = $current_category->{$category_path} ;
				}
				
			$categories->{$category} = $current_category ;
			$current_category->{_ENTRIES}++ ;
			push @{$current_category->{_FILES}}, $file ;
			
			$current_category->{'_REQUIREMENTS'}{$requirement_name} =  $current_requirement ;
			}
			
		$requirements_structure->{STATISTICS}{_REQUIREMENTS_IN_MULTIPLE_CATEGORIES}++ if @{$requirement->{CATEGORIES}} > 1 ;
		$requirements_structure->{STATISTICS}{_REQUIREMENTS_CATEGORIZED}++ ;
		}
	else
		{
		$requirements_structure->{NOT_CATEGORIZED}{_REQUIREMENTS}{$requirement_name} = $current_requirement ;
		$categories->{NOT_CATEGORIZED} = $requirements_structure->{NOT_CATEGORIZED} ;
		$categories->{NOT_CATEGORIZED}{_ENTRIES}++ ;
		}
	}

# handle requirements that were defined, as sub requirements, but for which no definition was found 
for my $requirement_name (keys %{$requirements})
	{
	if(exists $requirements->{$requirement_name}{DEFINITION_IS_MISSING})
		{
		$requirements_structure->{NOT_FOUND}{_REQUIREMENTS}{$requirement_name} = $requirements->{$requirement_name} ;
		$categories->{NOT_FOUND} = $requirements_structure->{NOT_FOUND} ;
		$categories->{NOT_FOUND}{_ENTRIES}++ ;

		delete $requirements->{$requirement_name}{DEFINITION};
		}
	}

$requirements_structure->{STATISTICS}{_REQUIREMENTS} = $ok_parsed ;
$requirements_structure->{STATISTICS}{_NOT_REQUIREMENTS} = $entries_with_wrong_type ;
$requirements_structure->{STATISTICS}{_LOADED} = scalar(keys %{$requirements}) ;

check_cycles($requirements_structure) ;

return ($requirements_structure, $requirements, $categories, $ok_parsed, $errors) ;
}

#--------------------------------------------------------------------------------------------------------------

sub check_cycles
{

=head2 check_cycles(\%requirements_structure)

Checks for cyclic dependencies in the requirements structure, it croaks if it finds one.

I<Arguments>

=over 2

=item * \%requirements_structure - A reference to the requirements structure.

=back

I<Returns>

=over 2

item * Nothing.

=back

=cut

my ($requirements_structure) = @_ ;

use Devel::Cycle ;
use IO::Capture::Stdout;

my $capture = IO::Capture::Stdout->new();

$capture->start();
find_cycle($requirements_structure) ;
$capture->stop();
my @all_cycless = $capture->read;

if(@all_cycless)
	{
	warn "Cyclic dependency check failed!:\n" ;
	warn join "\n", @all_cycless ;
	croak ;
	}
}

#------------------------------------------------------------------------------------------------------------------

sub check_requirement_content
{

=head2 check_requirement_content( xxx )

I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut


my ($template_definition, $requirement, $file ) = @_ ;

return undef unless($requirement) ;  # fail
	
my (%violations) ;

#~ print DumpTree $requirement, $file	;

for my $key (keys %$requirement)
	{
	if(exists $template_definition->{$key})
		{
		# check type
		if(ref $requirement->{$key} eq $template_definition->{$key}{TYPE})
			{
			# check scalar values
			if($template_definition->{$key}{TYPE} eq '' && exists $template_definition->{$key}{ACCEPTED_VALUES} )
				{
				my $is_valid = 0 ;
				
				for my $accepted_value (@{$template_definition->{$key}{ACCEPTED_VALUES}})
					{
					if(Compare($requirement->{$key}, $accepted_value))
						{
						$is_valid++ ;
						last ;
						}
					}
					
				push @{ $violations{$file}{errors} }, "'$key' invalid data" unless $is_valid ;
				}
				
			# check arrays
			if($template_definition->{$key}{TYPE} eq 'ARRAY')
				{
				for my $value (@{$requirement->{$key}})
					{
					if($value eq q{})
						{
						push @{ $violations{$file}{errors} }, "'$key' invalid data, empty string" ;
						}
					}
				}
			}
		else
			{
			push @{ $violations{$file}{errors} }, "'$key' invalid type" ;
			}
		}
	else
		{
		$violations{$file}{extra_keys}{$key} =  "non standard requirement field" ;
		}
	}

for my $key (keys %$template_definition)
	{
	unless(exists $requirement->{$key})
		{
		if(exists $template_definition->{$key}{OPTIONAL})
			{
			$violations{$file}{missing_keys}{$key}++ unless $template_definition->{$key}{OPTIONAL} ;
			}
		else
			{
			$violations{$file}{missing_keys}{$key}++ ;
			}
		}
	}

for (@{$requirement->{SUB_REQUIREMENTS} || []})
	{
	push @{ $violations{$file}{warnings}}, "sub-requirement '$_' is not a string"  unless (ref eq $EMPTY_STRING) ; 
	}

my ($basename, $path, $ext) = File::Basename::fileparse($file, ('\..*')) ;
push @{ $violations{$file}{errors} }, 'NAME field and file name mismatch' unless ($requirement->{NAME} eq $basename);

return $requirement, \%violations ;
}

#-------------------------------------------------------------------------------------------------------------------

sub get_requirements_violations
{

=head2 get_requirements_violations( xxx )


I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($master_template_file, $sources) = @_ ;

my $master_template = load_master_template($master_template_file) ;

my @files = get_files_to_check($sources) ;

my ($ok_parsed, $requirements_with_errors, %all_violations) = (0, 0) ;

for my $file (@files)
	{
	#~ print DumpTree $requirement, $file ;
	
	my ($requirement, $violations) = load_requirement($master_template, $file) ;
	
	if(defined $requirement) 
		{
		$ok_parsed++ ;
		$requirements_with_errors++ if exists $violations->{$file} ;
		
		$all_violations{$file} = $violations->{$file} if exists $violations->{$file} ;
		}
	}

return (\@files, $ok_parsed, $requirements_with_errors, \%all_violations) ;
}

#--------------------------------------------------------------------------------------------------------------

sub get_files_to_check
{

=head2 get_files_to_check( xxx )



I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($sources) = @_ ;

$sources = [$sources] unless 'ARRAY' eq ref $sources ;

my @files ;

for my $source (@{$sources})
	{
	if (defined $source)
		{
		if(-d $source)
			{
			push @files, File::Find::Rule->file()->name( '*.rat' )->in($source);
			}
		else
			{
			push @files, $source ;
			}
		}
	else
		{
		push @files, File::Find::Rule->file()->name( '*.rat' )->in( '.' );
		}
	}
	
return @files ;
}

#------------------------------------------------------------------------------------------------------------------

sub create_requirement
{

=head2 createRequirement($template, $elements)


I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($template, $elements)  = @_ ;

my $requirement = {} ;
tie %{$requirement}, 'Tie::IxHash', map {$_ => $template->{$_}{DEFAULT}} keys %{$template} ;

for my $element (keys %{$elements})
	{
	$requirement->{$element} = $elements->{$element} ;
	}
	
return $requirement ;
}

#--------------------------------------------------------------------------------------------------------------

sub load_requirement
{

=head2 load_requirement( $master_template, $file)

I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($master_template, $file) = @_ ;

my $requirement = do $file or croak "Error: Can't load requirement '$file': $@ $!"  ;

my $violations = {} ;

if(defined $requirement) 
	{
	my $type_template = get_type_template($file, $requirement, $master_template) ;
	
	$violations = check_requirement_content($type_template, $requirement, $file) ;
	}
else
	{
	$violations->{$file}{errors} = ["Error: can't parse requirement '$file':$@\n"] ;
	}

$requirement->{_LOADED_FROM} = $file ;

return ($requirement, $violations) ;
}

sub display_load_requirement_errors
{
my ($violations) = @_ ;

print DumpTree($violations, "Violations:", DISPLAY_ADDRESS => 0) ;
}

#-------------------------------------------------------------------------------------------------------------------

sub get_type_template
{

=head2 ( xxx )



I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($file, $requirement, $master_template) = @_ ;

croak 'Invalid argument!' unless(defined $requirement) ;
croak 'Invalid argument!' unless(defined $master_template) ;

my $type_template ;

if(defined $requirement->{TYPE})
	{
	#Todo: use the types defined in the master template instead for a static list
	if($requirement->{TYPE} eq 'requirement')
		{
		$type_template = $master_template->{REQUIREMENT}
		}
	elsif($requirement->{TYPE} eq 'use case')
		{
		$type_template = $master_template->{USE_CASE}
		}
	else
		{
		croak "Invalid TYPE \"$requirement->{TYPE}\"! in '$file'"
		}
	}
else
	{
	croak "Missing TYPE! in '$file'" ;
	}

$type_template ;
}

#--------------------------------------------------------------------------------------------------------------

sub check_requirements
{

=head2 ( xxx )



I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($master_template_file, $sources) = @_ ;

my ($files, $ok_parsed, $requirements_with_errors, $violations) = get_requirements_violations($master_template_file, $sources) ;

for my $file (sort keys %{ $violations })
	{
	print DumpTree($violations->{$file}, "Violations for '$file':", DISPLAY_ADDRESS => 0) ;
	}

print pluralize ("{No|%d} requirement{s||s} found. {No|%d} valid requirement{s||s}\n", scalar(@{$files}), $ok_parsed - $requirements_with_errors) ;
}

#--------------------------------------------------------------------------------------------------------------

sub show_abstraction_level
{

=head2 ( xxx )



I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($requirements) = @_ ;

for my $requirement_name (keys %{$requirements})
	{
	if(exists $requirements->{$requirement_name}{DEFINITION}{ABSTRACTION_LEVEL})
		{
		$requirements->{$requirement_name}{_ABSTRACTION_LEVEL} = $requirements->{$requirement_name}{DEFINITION}{ABSTRACTION_LEVEL} ;
		}
	}
}

#-------------------------------------------------------------------------------------------------------------------

sub count_missing_elements
{

=head2 ( xxx )



I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($requirements_structure) = @_ ;

if(exists $requirements_structure->{NOT_FOUND})	
	{
	$requirements_structure->{NOT_FOUND }{_MISSING_REQUIREMENTS_ENTRIES}
		= 0 + scalar keys %{$requirements_structure->{NOT_FOUND}{_REQUIREMENTS}} ;
	}
	
if(exists $requirements_structure->{NOT_CATEGORIZED})	
	{
	$requirements_structure->{NOT_CATEGORIZED }{_NUMBER_OF_REQUIREMENTS} 
		= 0 + scalar keys %{$requirements_structure->{NOT_CATEGORIZED}{_REQUIREMENTS}} ;
	}
}

#-------------------------------------------------------------------------------------------------------------------

1 ;

