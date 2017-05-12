
package App::Requirement::Arch::HTML::Flat ;

use strict ;
use warnings ;
use Data::Dumper;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(generate_flat_html_document) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.01';
}

use App::Requirement::Arch::Format::Flat qw(generate_flat_document_structure) ;

=head1 NAME

	App::Requirement::Arch::HTML::Flat - Generate a "flat" HTML document from a requirement structure

=head1 SYNOPSIS

	use App::Requirements::Arch::HTML::Flat ;
	use App::Requirements::Arch::Filter ;
	
	my ($requirements_structure, $requirements, $categories) 
		= load_and_filter_requirements( ...) ;

	keep_abstraction_level_requirements($requirements, @keep_abstraction_level) ;
	
	my $html_document = generate_flat_html_document($requirements, $title, $header, $comment) ;

=head1 DESCRIPTION

This module provides functionality to generate a 'flat' (as opossed to the hierarchical structure used when developing
requirements) HTML requirements document to be read by users not part of the requirements development.

=head1 SUBROUTINES/METHODS

=cut

sub generate_flat_html_document
{
=head2

Generate a 'flat' HTML requirements document. After transforming the requirements structure to a flat structure.
Useful for reviews with reviwers that are  not used to structured hierarchical requirement visualisation.

I<Arguments>

=over 2

=item * \%requirements - A reference to the requirements stucture to process.

=item * $title - The title of the generated HTML document.

=item * $header - header to put in generated HTML document below the title.

=item * $comment - Comment to add to the source of the generated HTML document. Will not be visible in a browser.

=back

I<Returns>

=over 2

item * $html_page - A HTML page.

=back

=cut

my ($requirements, $title, $header, $comment) = @_;
my $flat_document_structure = generate_flat_document_structure($requirements);
return generate_html($flat_document_structure, $requirements, $title, $header, $comment)
}

#-----------------------------------------------------------------------------------------

sub generate_html
{

=head2 generate_html($flat_document_structure, \%requirements, $title, $header, $comment)

Generate a 'flat' HTML requirements document. 

I<Arguments>

=over 2

=item * %flat_document_structure - A reference to a structure to be used to generate the HTML document

=item * \%requirements - A reference to a hash containing requirements

=item * $title - The title of the generated HTML document

=item * $header - A string which will be inserted as-is in the HTML document, under the title

=item * $comment - A string that is inserted as a comment 

=back

I<Returns> 

=over 2

=item * $html - A string containing the HTML document

=back

=cut

my ($flat_document_structure, $requirements, $title, $header, $comment) = @_;

# Generate the index
my $page_index = 
	extract_from_flat_requirements
		(
		$flat_document_structure,
		$requirements,
		\&generate_categories_links,
		\&generate_requirements_links
		);
	
# Generate the contents
my $page_contents = 
	extract_from_flat_requirements
		(
		$flat_document_structure,
		$requirements,
		\&generate_categories_html,
		\&generate_requirement_html
		);

$title = 'No title set for this document!' unless ($title);

return <<"END_OF_HTML";
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
 
	<head>
		<!-- $comment -->
		<title>$title</title>
		<style type="text/css">
			body,form{
				margin: 0;
				margin-right: 15%;
			}
			pre {
				background-color: #FFFFFF;
				font-family: monospace;
				font-size: 9pt;
				color: #000000;
			}
			body {
				background-color: #FFFFFF;
				font-family: verdana,arial,helvetica,sans-serif;
				font-size: 10pt;
				color: #000000;
			}
			select {
				font-size: 10pt;
				font-family: Verdana,sans-serif;
			}
			h1{
				font-size: 14pt;
			}
			h2{
				font-size: 13pt;
			}
			h3 {
				font-size: 12pt;
			}
			h4 {
				font-size: 11pt;
			}
			h5 {
				font-size: 10pt;
			}
			hr {
				color: #003399;
				height: 2px;
			}
		</style>
	</head>
	<body>
		<h1>$title</h1>
		<p>$header</p>

		<h1>Index</h1>
		<div style="margin-left: 3em;">
$page_index
		</div>
		<hr />
		<div style="margin-left: 1em;">
$page_contents
		</div>
		<p><img src='http://www.w3.org/Icons/valid-xhtml10'  height="15" width='44' /></p>
	</body>
</html>
END_OF_HTML

}

#-----------------------------------------------------------------------------------------

sub transformt_text_to_html
{

=head2 transformt_text_to_html($string_to_htmlize)

Transform text elements to their HTML equivalent

I<Arguments>

=over 2

=item * $string_to_htmlize

=back

I<Returns> 

=over 2

=item * $html - transformed text

=back

=cut

my ($string_to_htmlize) = @_;
$string_to_htmlize=~ s/\&/\&amp;/gsm;
$string_to_htmlize=~ s/\t/    /gsm;
$string_to_htmlize=~ s/\ /\&nbsp;/gsm;
$string_to_htmlize=~ s/\n|(\n\r)/<br \/>/gsm;

return $string_to_htmlize ;
}

#-----------------------------------------------------------------------------------------

sub extract_from_flat_requirements
{

=head2 extract_from_flat_requirements(\%flat_document_structure, \%$requirements, \@levels, \&process_category, \&process_requirement)

Walks the flat requirement structur structure, for each category, and calls the passed subs

I<Arguments>

=over 2

=item * \%flat_document_structure - The flat document strucure generated by 'generate_flat_document_structure'.

=item * \%requirements - The actual requirements. Needed as the flat requirements structure only reference data in this structure.

=item * \&process_category - A sub called on each category

=item * \&process_requirement- A sub called on each requirement within the category

=back

I<Returns>

=over 2

=item * A text string containing all generated data.

=back

=cut

my ($flat_document_structure, $requirements, $process_category, $process_requirements) = @_;

my ($header_level, $index) = (1, 1) ;
my $generated_data = '' ;

for my $category (sort keys %{$flat_document_structure->{CATEGORY_SORT}})
	{
	my $requirements_per_category = {};

	for my $level (sort keys %{$flat_document_structure->{CATEGORY_SORT}{$category}})
		{
		for my $requirement_name (sort keys %{$flat_document_structure->{CATEGORY_SORT}{$category}{$level}})
			{
			$requirements_per_category->{$requirement_name} = $requirements->{$requirement_name};
			}
		}
		
	$generated_data .= $process_category->($header_level, $category, $index);
	$generated_data .= process_requirements($requirements_per_category, $process_requirements, $header_level + 1, "$index.");
	
	$index++;
	}

return $generated_data ;
}

#-----------------------------------------------------------------------------------------

sub process_requirements
{

=head2 process_requirements(\%requirements, \&process_requirements, $header_level, $parent_path)

Walks the requirements structure and apply a sub to each requirement

I<Arguments>

=over 2

=item * \%requirements - The requirements.

=item * \&process_requirements - Reference to a sub that will be applied to each requirements.

=item * $header_level - The header level to use.

=item * $parent_path - The path to the current requirement

=back

I<Return>

=over 2

=item * A text string containing all generated data.

=cut

my ($requirements, $process_requirements, $header_level, $parent_path) = @_;

my $return_data = '';

$parent_path = '' unless ($parent_path);
$header_level = 1 unless ($header_level);

my $current_id = 1;

for my $requirement_name (sort keys %{$requirements})
	{
	$return_data .= $process_requirements->($requirements, $requirement_name, $header_level, $parent_path, $current_id);

	if (exists $requirements->{$requirement_name}{SUB_REQUIREMENTS})
		{
		my $sub_requirements = $requirements->{$requirement_name}{SUB_REQUIREMENTS};
		$return_data .= process_requirements($sub_requirements, $process_requirements, $header_level + 1, "$parent_path$current_id.");
		}

	$current_id++;
	}

return $return_data;
}

#-----------------------------------------------------------------------------------------

sub generate_categories_links
{

=head2 generate_categories_links($header_level, $category, $index)


I<Arguments>

=over 2

=item * $header_level - The level of the category

=item * $category, -  The name of the category

=item *  $index - uniq index for the category

=back

I<Returns>

=over 2

=item * A string containing a HTML link for the category

=back

=cut

my ($header_level, $category, $index) = @_;

my $indent = "\t"x($header_level + 1);
my $new_category = transformt_text_to_html($category);

return <<END_OF_INDEX_SECTION;
$indent\t<h$header_level>
$indent\t\t<a href=\"#$index\">$index. $new_category </a>
$indent\t</h$header_level>
END_OF_INDEX_SECTION
}

#-----------------------------------------------------------------------------------------

sub generate_categories_html
{

=head2 generate_categories_html($header_level, $category, $index)

Generates HTML for a category.

I<Arguments>

=over 2

=item * $header_level - The level of the category

=item * $category, -  The name of the category

=item *  $index - uniq index for the category

=back

I<Returns>

=over 2

=item * A string containing a HTML representation for the category

=back

=cut

my ($header_level, $category, $index) = @_;

my $indent = "\t"x($header_level + 1);
my $new_category = transformt_text_to_html($category);

return <<END_OF_INDEX_SECTION;
$indent\t<h$header_level>
$indent\t\t<a name=\"$index\"></a> $index. $new_category
$indent\t</h$header_level>
END_OF_INDEX_SECTION
}

#-----------------------------------------------------------------------------------------

sub generate_requirements_links
{

=head2 index_generation(\%requirements, $requirement_name, $header_level, $parent_path, $current_id)

This function will be called once per requirement, and subrequirements, to generate anHTML link.

I<Arguments>

=over 2

=item * \%requirements - The requirements structre.

=item * $requirement_name - The name of the requirement.

=item * $header_level - The level of the requirement.

=item * $parent_path - A string reprecenting the path to the requirement.

=item * $current_id - The id of the current requirement.

=back

I<Returns>

=over 2

=item * A string containing a HTML link for the category

=back

=cut

my ($requirements, $requirement_name, $header_level, $parent_path, $current_id) = @_;

my $indent = "\t"x($header_level + 1);
my $index = "$parent_path$current_id";

my $header = $header_level > 5 ? 5 : $header_level;

my $entry_name 
	= transformt_text_to_html
		(
		exists $requirements->{$requirement_name}{DEFINITION} 
			? "$requirement_name" 
			: "$requirement_name (Definition Missing)"
		);
	

return <<END_OF_INDEX_SECTION;
$indent\t<h$header>
$indent\t\t<a href=\"#$index\">$index $entry_name</a>
$indent\t</h$header>
END_OF_INDEX_SECTION
}

#-----------------------------------------------------------------------------------------

sub generate_requirement_html
{

=head2 generate_requirement_html(\%requirements, $requirement_name, $header_level, $parent_path, $current_id)

This function is called for each requirement, and subrequirements,  to generate a HTML representation of the requirement.

I<Arguments>

=over 2

=item * \%requirements - The requirements structre.

=item * $requirement_name - The name of the requirement.

=item * $header_level - The header level.

=item * $parent_path - A string reprecenting the path to the requirement.

=item * $current_id - The id of the current requirement.

=back

I<Returns>

=over 2

=item * A string containing a HTML representation for the requirement.

=back

=cut

my ($requirements, $requirement_name, $header_level, $parent_path, $current_id) = @_;

my $indent = "\t"x($header_level + 1);
my $index = "$parent_path$current_id";

my $return_data = '';
my $header = $header_level > 5 ? 5 : $header_level;

my $entry_name = transformt_text_to_html($requirement_name) ;

$return_data .= <<END_OF_PAGE_SECTION;
$indent\t<a name="$index"></a>
$indent\t<h$header>$index $entry_name</h$header>
$indent\t<div style="margin-left: 3em;">
END_OF_PAGE_SECTION

if (exists $requirements->{$requirement_name}{DEFINITION_IS_MISSING})
	{
	$return_data .= "$indent\t\t<i>Missing description.</i>\n";
	}
else
	{
	for my $field_name (sort keys %{$requirements->{$requirement_name}{DEFINITION}})
		{
		# Make,eg:,  'ABSTRACTION_LEVEL' in to 'Abstraction Level'	
		my $new_field_name = join (' ', map { ucfirst lc $_ } split(/_/, $field_name));

		if (ref ($requirements->{$requirement_name}{DEFINITION}{$field_name}) eq 'ARRAY')
			{
			if (scalar @{$requirements->{$requirement_name}{DEFINITION}{$field_name}} > 0)
				{
				$return_data .= "$indent\t\t<p><b>$new_field_name</b>\n";
				$return_data .= "$indent\t\t\t<ul>\n";

				for my $entry (@{$requirements->{$requirement_name}{DEFINITION}{$field_name}})
					{
					$return_data .= "$indent\t\t\t\t<li>" . transformt_text_to_html($entry) . "</li>\n";
					}

				$return_data .= "$indent\t\t\t</ul>\n";
				$return_data .= "$indent\t\t</p>\n";
				}
			else
				{
				$return_data .= "$indent\t\t<p><b>$new_field_name:</b> not defined.</p>\n"
				}
			}
		else
			{
			warn "$requirement_name->$field_name" unless (defined $requirements->{$requirement_name}{DEFINITION}{$field_name});
			$return_data .= "$indent\t\t<p><b>$new_field_name:</b> " . transformt_text_to_html($requirements->{$requirement_name}{DEFINITION}{$field_name}) . "</p>\n";
			}
		}
	}

$return_data .= "$indent\t</div>\n";
return $return_data;
}

#-----------------------------------------------------------------------------------------

=head1 TO DO

Tags over <h6>, this would be a problem if we generate the whole requirement structure as we have more than 6 level of requirement breakdown.

=head1 SEE ALSO

=head1 AUTHOR

     Khemir Nadim ibn Hamouda.
     Ian Kumlien

=cut

#------------------------------------------------------------------------------------------------------------------

1 ;

