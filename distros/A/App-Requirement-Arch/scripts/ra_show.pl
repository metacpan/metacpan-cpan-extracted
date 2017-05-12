#!/usr/bin/perl

use strict ;
use warnings ;
use Carp ;

use Getopt::Long;
use File::Slurp ;

use App::Requirement::Arch qw(get_template_files load_master_template) ;

#~ use App::Requirement::Arch::Requirements qw(CreateRequirement)  ;
use App::Requirement::Arch::Filter qw(load_and_filter_requirements) ;
use App::Requirement::Arch::HTML::Flat qw(generate_flat_html_document) ;

use Data::TreeDumper ;
use Data::TreeDumper::Utils qw(first_nsort_last_filter) ;

#------------------------------------------------------------------------------------

sub display_help
{
warn <<'EOH' ;

NAME
  ra_show

SYNOPSIS
  $ ra_show --include_type requirement --include_description_data --show_abstraction_level --include_categories --format [dhtml|text| path/to/requirements

DESCRIPTION
  This utility will parse the requirements passed as argument and generate 
  a document in text or DHTML format. The  structure reflects the 
  categorization of the  requirements. categories inherited from parent
  requirements are taken into acount.
	
ARGUMENTS
  --master_template_file        file containing the master template

  --master_categories_file      file containing the categories template

  --include_type type           include entries with type in the document.
                                valid types are defined in file:
				  master_template.txt
  
  --format                      set the output format
  
	dhtml: structured DHTML output
		--show_abstraction_level  include the abstraction level in
					  the output
		--requirement_fields_filter_file

	text: structured text output
		--show_abstraction_level  include the abstraction level in
					  the output
		--requirement_fields_filter_file
	
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
	$show_abstraction_level, 
	$flat_html_title, $flat_html_header_file, $flat_html_comment,
	$include_loaded_from,
	$master_template_file, $master_categories_file,
	$requirement_fields_filter_file, $flat_requirement_fields_filter_file,
	) ;



my $format = '' ;

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
		'format=s' => \$format,
		'include_loaded_from' => \$include_loaded_from,
		'master_template_file=s' => \$master_template_file,
		'master_categories_file=s' => \$master_categories_file,
		'requirement_fields_filter_file=s' => \$requirement_fields_filter_file, 
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
					format
					include_loaded_from
					master_template_file
					master_categories_file
					requirement_fields_filter_file
					help
					) ;
				exit(0) ;
				},
		
		) ;

display_help() unless @ARGV ;

unless($format)
  {
  warn "Error: no output format specified!\n" ;
  display_help()
  }

my $sources = \@ARGV ;

($master_template_file, $master_categories_file)  = get_template_files($master_template_file, $master_categories_file)   ;

use File::HomeDir ;
$requirement_fields_filter_file = home() . '/.ra/field_filters/requirement_fields.pl'  unless(defined $requirement_fields_filter_file) ;
$flat_requirement_fields_filter_file = home() . '/.ra/field_filters/flat_requirement_fields.pl'  unless(defined $flat_requirement_fields_filter_file) ;

my %requirement_fields = (get_filter_data($requirement_fields_filter_file, ['ORIGINS', 'DESCRIPTION', 'LONG_DESCRIPTION', 'RATIONALE'])) ;
$requirement_fields{'_LOADED_FROM'} = 1 if $include_loaded_from ;

for($format)
	{
	/^text/ and do
		{
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
				$include_description_data,
				\%requirement_fields,
				1,  #$display_multiline_as_array,
				$include_categories,
				\@include_types,
				) ;

		generate_text_document($requirements_structure) ;
		last ;
		} ;
	
	/^dhtml/ and do
		{
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
				$include_description_data,
				\%requirement_fields,
				1, #$display_multiline_as_array,
				$include_categories,
				\@include_types,
				) ;
				
		generate_dhtml_document($requirements_structure) ;
		last ;
		} ;
		
	croak "Error: Invalid format '$format'!\n" ;
	}


#-------------------------------------------------------------------------------

sub  get_filter_data
{
my ($filter_file, $default_filter) = @_ ;

my @filter_data ;

if(-f $filter_file)
	{
	@filter_data = do $filter_file or warn "Warning: Can't load fields filter file '$filter_file': $@\nUsing default filter.\n" ;
	}
else
	{
	warn "Warning: Can't find fields filter file '$filter_file', using default filter.\n" ;
	@filter_data = map {$_ => 1} @{$default_filter} ;
	}

return @filter_data ;
}

#-------------------------------------------------------------------------------

sub generate_text_document
{
my ($requirements_structure) = @_ ;

print DumpTree
	(
	$requirements_structure,
	'Requirements structure:',
	NO_NO_ELEMENTS => 1,
	FILTER => \&first_nsort_last_filter,
	FILTER_ARGUMENT => {AT_END => [qr/NOT_CATEGORIZED/, qr/NOT_FOUND/, qr/STATISTICS/]},
	) ;
}

#-------------------------------------------------------------------------------

sub generate_dhtml_document
{
my ($requirements_structure) = @_ ;

my $style ;
my $body = DumpTree
	(
	$requirements_structure,
	'Requirements structure',
	NO_NO_ELEMENTS => 1,
	RENDERER => 
		{
		NAME => 'DHTML',
		STYLE => \$style,
		BUTTON =>
			{
			COLLAPSE_EXPAND => 1,
			SEARCH => 1
			}
		},
		
	FILTER => \&first_nsort_last_filter,
	FILTER_ARGUMENT =>  {AT_END => [qr/NOT_CATEGORIZED/, qr/NOT_FOUND/, qr/STATISTICS/]},
	) ;
	
  
print <<EOT;
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html 
PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
>

<html>

<!--
Automatically generated by Perl and Data::TreeDumper::DHTML
-->

<head>
<title>Requirements</title>

$style
</head>
<body>
$body
</body>
</html>
EOT
}
