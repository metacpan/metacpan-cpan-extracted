package App::Office::Contacts::Donations::Controller::Initialize;

use parent 'App::Office::Contacts::Donations::Controller';
use strict;
use warnings;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.10';

# -----------------------------------------------

sub build_head_js
{
	my($self, $search_js) = @_;

	$self -> log(debug => 'Entered build_head_js');

	my($add_organization_js)       = $self -> param('view') -> organization -> build_add_organization_js;
	my($add_person_js)             = $self -> param('view') -> person -> build_add_person_js;
	my($detail_js)                 = $self -> param('view') -> build_display_detail_js;
	my($organization_donations_js) = $self -> param('view') -> donations -> build_donations_js('organization');
	my($person_donations_js)       = $self -> param('view') -> donations -> build_donations_js('person');
	my($organization_notes_js)     = $self -> param('view') -> notes -> build_notes_js('organization');
	my($person_notes_js)           = $self -> param('view') -> notes -> build_notes_js('person');
	my($report_js)                 = $self -> param('view') -> report -> build_update_report_js;
	my($update_organization_js)    = $self -> param('view') -> organization -> build_update_organization_js;
	my($update_person_js)          = $self -> param('view') -> person -> build_update_person_js;

	# These things are being declared globally within the web page.

	my($head_js) = <<EJS;
$detail_js
$add_organization_js
$update_organization_js
$add_person_js
$update_person_js
$search_js
$organization_donations_js
$person_donations_js
$organization_notes_js
$person_notes_js
$report_js

function make_organization_donations_focus(eve)
{
document.organization_update_donations_form.amount_input.focus();
}

function make_organization_notes_focus(eve)
{
document.organization_update_notes_form.note.focus();
}

function make_person_donations_focus(eve)
{
document.person_update_donations_form.amount_input.focus();
}

function make_person_notes_focus(eve)
{
document.person_update_notes_form.note.focus();
}

function make_report_focus(eve)
{
	//document.report_form.report_id.focus();
}

function make_search_name_focus(eve)
{
	document.search_form.target.focus();
}

function make_update_name_focus(eve)
{
	document.update_organization_form.name.focus();
}

function make_update_given_names_focus(eve)
{
	document.update_person_form.given_names.focus();
}

var inner_tab_set = new YAHOO.widget.TabView();
var tab_set = new YAHOO.widget.TabView();

// We have explicit variables so we can delete and recreate
// some of them whenever another set of details are displayed.

var about_tab;
var add_tab;
var search_tab;

var add_person_tab;
var person_donations_tab;
var person_tab;
var person_notes_tab;

var add_organization_tab;
var organization_donations_tab;
var organization_tab;
var organization_notes_tab;

var from_calendar;
var to_calendar;

var report_tab;

EJS

	return $head_js;

} # End of build_head_js.

# -----------------------------------------------

sub display
{
	my($self)        = @_;
	my($cookie_name) = 'donations';

	$self -> log(debug => 'Entered display');

	return 'Invalid cookie digest' if ($self -> validate_post($cookie_name) == 0);

	$self -> generate_cookie($cookie_name);

	return $self -> build_web_page;

} # End of display.

# -----------------------------------------------

1;
