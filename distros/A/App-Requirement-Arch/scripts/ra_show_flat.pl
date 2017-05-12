#!/usr/bin/perl

use strict ;
use warnings ;

use Getopt::Long;
use File::Slurp ;

use App::Requirement::Arch qw(get_template_files load_master_template) ;

#~ use App::Requirement::Arch::Requirements qw(create_requirement)  ;
use App::Requirement::Arch::Filter qw(load_and_filter_requirements) ;
use App::Requirement::Arch::HTML::Flat qw(generate_flat_html_document) ;

use Data::TreeDumper ;
use Data::TreeDumper::Utils qw(first_nsort_last_filter) ;

#------------------------------------------------------------------------------------

sub display_help
{
warn <<'EOH' ;

NAME
  ra_show_flat

SYNOPSIS
  $ ra_show_flat --include_type type --include_description_data --keep_abstraction_level abstraction_level --show_abstraction_level --include_categories path/to/requirements

DESCRIPTION
  Generates a 'flat' document where the requiremetns are listed without hierarchical relationship.
  
ARGUMENTS
  --master_template_file        file containing the master template

  --master_categories_file      file containing the categories template

  --include_type type           include entries with type in the document.
                                valid types are defined in file:
				  master_template.txt
  
  --keep_abstraction_level abstraction_level
				define which requirements are kept in
				the generated document. 
				
				multiple --keep_abstraction_level can be
				specified. valid types are defined in the 
				master template.

  --title         the title of the flat_html document
  
  --header_file   a file name which content will be prepended
  		to the generated document
  --comment       a comment inserted in the generated html document
  
  --flat_requirement_fields_filter_file  file containing the requirement 
					 fields to keep

  --include_description_data    include the following fields in the output
				  ORIGIN
				  DESCRIPTION
				  LONG_DESCRIPTION
				  RATIONALE
				      
  --include_categories          the document will contain the categories field
  
  --remove_empty_requirement_field_in_categories
				categories without requirements will not 
				include the '_REQUIREMENTS' field
  
  --include_statistics          include the statistics gathered while parsing 
                                the requirements
				
  --include_not_found           include the section about referenced but not 
                                found requirements
  --include_loaded_from         include where the physical file location of the
                                requirement is
  
Output
	The document is output on STDOUT.
	
	Information about the master categories and categories used
	in the requirements is output on STDERR.
	
AUTHORS
  Khemir Nadim ibn Hamouda.

EOH

exit(1) ;
}

#------------------------------------------------------------------------------------

my 
	(
	@include_types, $include_description_data,
	$include_categories, $remove_empty_requirement_field_in_categories,
	$include_not_found, $include_statistics,
	$show_abstraction_level, @keep_abstraction_level,
	$flat_html_title, $flat_html_header_file, $flat_html_comment,
	$include_loaded_from,
	$master_template_file, $master_categories_file,
	$requirement_fields_filter_file, $flat_requirement_fields_filter_file,
	) ;

die 'Error parsing options!'unless 
	GetOptions
		(
		'include_type=s' => \@include_types,
		'include_description_data' => \$include_description_data,
		'include_categories' => \$include_categories,
		'remove_empty_requirement_field_in_categories' => \$remove_empty_requirement_field_in_categories,
		'include_not_found' => \$include_not_found,
		'include_statistics' => \$include_statistics,
		'show_abstraction_level' => \$show_abstraction_level, 
		'keep_abstraction_level=s' => \@keep_abstraction_level,
		'title=s' => \$flat_html_title,
		'header_file=s' => \$flat_html_header_file,
		'comment=s' => \$flat_html_comment,
		'include_loaded_from' => \$include_loaded_from,
		'master_template_file=s' => \$master_template_file,
		'master_categories_file=s' => \$master_categories_file,
		'flat_requirement_fields_filter_file=s' => \$flat_requirement_fields_filter_file,
		'h|help' => \&display_help, 
		
		'dump_options' => 
			sub 
				{
				print join "\n", map {"-$_"} 
					qw(
					include_type
					include_description_data
					include_categories
					remove_empty_requirement_field_in_categories
					include_not_found
					include_statistics
					show_abstraction_level
					keep_abstraction_level
					title
					header_file
					comment
					include_loaded_from
					master_template_file
					master_categories_file
					flat_requirement_fields_filter_file
					help
					) ;
				exit(0) ;
				},
		
		) ;

display_help() unless @ARGV ;

my $sources = \@ARGV ;

($master_template_file, $master_categories_file)  = get_template_files($master_template_file, $master_categories_file)   ;

use File::HomeDir ;
$requirement_fields_filter_file = home() . '/.ra/field_filters/requirement_fields.pl'  unless(defined $requirement_fields_filter_file) ;
$flat_requirement_fields_filter_file = home() . '/.ra/field_filters/flat_requirement_fields.pl'  unless(defined $flat_requirement_fields_filter_file) ;

my %flat_requirement_fields = (get_filter_data($flat_requirement_fields_filter_file, [qw(CATEGORIES ABSTRACTION_LEVEL ORIGINS DESCRIPTION LONG_DESCRIPTION RATIONALE SUB_REQUIREMENTS)])) ;
$flat_requirement_fields{'_LOADED_FROM'} = 1 if $include_loaded_from ;

my ($requirements_structure, $requirements, $categories) 
	= load_and_filter_requirements
		(
		$sources,
		$master_template_file,
		$master_categories_file,
		$show_abstraction_level,
		$remove_empty_requirement_field_in_categories,
		$include_not_found,
		$include_statistics,
		1, # $include_description_data,
		\%flat_requirement_fields,
		0, #$display_multiline_as_array,
		1, #$include_categories,
		\@include_types,
		) ;

keep_abstraction_level_requirements($requirements, @keep_abstraction_level) ;

generate_flat_html_document_from_requirements($requirements, $flat_html_title, 
	$flat_html_header_file, $flat_html_comment) ;


#-------------------------------------------------------------------------------

sub  get_filter_data
{
my ($filter_file, $default_filter) = @_ ;

my @filter_data ;

if(-f $filter_file)
	{
	@filter_data = do $filter_file or warn "Warning: Can't load fields filter file '$filter_file', using default filter.\n" ;
	}
else
	{
	warn "Warning: Can't find fields filter file '$filter_file', using default filter to keep fields:\n" ;
	warn "\t$_\n" for @{$default_filter} ;
	
	@filter_data = map {$_ => 1} @{$default_filter} ;
	}

return @filter_data ;
}

#-------------------------------------------------------------------------------

sub generate_flat_html_document_from_requirements
{
my ($requirements, $title, $header_file, $comment) = @_ ;

$comment = '' unless ($comment);

my $header = '';
$header = read_file($header_file) if ($header_file);

print generate_flat_html_document($requirements, $title, $header, $comment) ;
}

sub keep_abstraction_level_requirements
{
my ($requirements, @abstraction_levels) = @_ ;

my %abstraction_levels_to_keep = map {$_ => 1} @abstraction_levels ;
my %requirements_to_delete ;

for my $requirement_name (keys %{$requirements})
	{
	unless (exists $requirements->{$requirement_name }{DEFINITION}{ABSTRACTION_LEVEL})
		{
		$requirements->{$requirement_name }{DEFINITION}{ABSTRACTION_LEVEL} = 'none' ;
		}
		
	unless (exists $abstraction_levels_to_keep{$requirements->{$requirement_name }{DEFINITION}{ABSTRACTION_LEVEL}})
		{
		$requirements_to_delete{$requirement_name}++ ;
		}
		
	for my $sub_requirement_name (keys %{$requirements->{$requirement_name}{SUB_REQUIREMENTS}})
		{
		my $sub_requirement = $requirements->{$requirement_name}{SUB_REQUIREMENTS}{$sub_requirement_name} ;
		
		unless
			(
			exists $sub_requirement->{DEFINITION}{ABSTRACTION_LEVEL}
			&& exists $abstraction_levels_to_keep{$sub_requirement->{DEFINITION}{ABSTRACTION_LEVEL}}
			)
			{
			$requirements_to_delete{$sub_requirement_name}++ ;
			delete $requirements->{$requirement_name}{SUB_REQUIREMENTS}{$sub_requirement_name} ;
			}
		}
	}
	
delete $requirements->{$_} for (keys %requirements_to_delete) ;

warn 'Abstraction level filter kept ' . scalar(keys %{$requirements}) . ' entries  [' . join(', ', @abstraction_levels) . "]\n" ;
}
