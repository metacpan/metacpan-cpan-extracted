package App::Office::Contacts::Import::vCards::View::vCards;

use JSON::XS;

use Moose;

extends 'App::Office::Contacts::View::Base';

use namespace::autoclean;

our $VERSION = '1.12';

# -----------------------------------------------

sub build_import_vcards_form
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_import_vcards_form');

	my($form) = $self -> load_tmpl('import.vcards.tmpl');

	# Output menus which apply to all imported people.
	# Matches code in App::Office::Contacts::Import::vCards::Controller::Import,
	# sub import_callback().

	for my $table (qw/broadcasts communication_types roles/)
	{
		$form -> param($table => $self -> build_select($table) );
	}

	$form -> param(sid => $self -> session -> id);

	# Make YUI happy by turning the HTML into 1 long line.

	$form = $form -> output;
	$form =~ s/\n//g;

	return $form;

} # End of build_import_vcards_form.

# -----------------------------------------------

sub build_import_vcards_js
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_import_vcards_js');

	my($js) = $self -> load_tmpl('import.vcards.js');

	$js -> param(form_action => $self -> script_name);

	return $js -> output;

} # End of build_import_vcards_js.

# -----------------------------------------------

sub format
{
	my($self, $output) = @_;

	$self -> log(debug => 'Entered format');

	return JSON::XS -> new -> utf8 -> encode({results => [@$output]});

} # End of format.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
