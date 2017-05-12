package App::Office::Contacts::Donations::Controller::Donations;

use parent 'App::Office::Contacts::Donations::Controller';
use strict;
use warnings;

use App::Office::Contacts::Donations::Util::Validator;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.10';

# -----------------------------------------------

sub add
{
	my($self) = @_;

	$self -> log(debug => 'Entered add');

	my($id)          = $self -> query -> param('target_id');
	my($type)        = $self -> param('id');
	my($method)      = "get_${type}_via_id";
	my($entity)      = $self -> param('db') -> $type -> $method($id);
	my($entity_name) = $$entity{'name'};
	my($input)       = App::Office::Contacts::Donations::Util::Validator -> new
	(
		config => $self -> param('config'),
		db     => $self -> param('db'),
		query  => $self -> query,
	) -> donations;
	my($report)      = $self -> param('view') -> donations -> report_add($self -> param('user_id'), $input, $type, $id, $entity_name);

	return $self -> display($report);

} # End of add.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add delete update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete
{
	my($self) = @_;

	$self -> log(debug => 'Entered delete');

	my($id)           = $self -> query -> param('target_id');
	my($type)         = $self -> param('id');
	my($method_name)  = "get_${type}_via_id";
	my($entity)       = $self -> param('db') -> $type -> $method_name($id);
	my($entity_name)  = $$entity{'name'};
	my(@donations_id) = split(/,/, $self -> query -> param('donations_id') );

	# Discard the 0.

	shift @donations_id;

	my($count) = $self -> param('db') -> donations -> delete($entity, $id, @donations_id);

	$self -> display("Deleted $count donation" . ($count == 1 ? '' : 's') . " for '$entity_name'");

} # End of delete.

# -----------------------------------------------

sub display
{
	my($self, $report) = @_;

	$self -> log(debug => 'Entered display');

	my($id)     = $self -> query -> param('target_id');
	my($type)   = $self -> param('id');
	my($method) = "${type}_donations";

	return $self -> $method($id, $report);

} # End of display.

# -----------------------------------------------

sub organization_donations
{
	my($self, $id, $report) = @_;

	$self -> log(debug => 'Entered organization_donations');

	my($organization) = $self -> param('db') -> organization -> get_organization_via_id($id);
	my($donation)     = $self -> param('db') -> donations -> get_donations('organizations', $id);
	my($result)       = $self -> param('view') -> donations -> display($id, $organization, $donation, 'organization', $report);

	return $result;

} # End of organization_donations.

# -----------------------------------------------

sub person_donations
{
	my($self, $id, $report) = @_;

	$self -> log(debug => 'Entered person_donations');

	my($person)   = $self -> param('db') -> person -> get_person_via_id($id);
	my($donation) = $self -> param('db') -> donations -> get_donations('people', $id);
	my($result)   = $self -> param('view') -> donations -> display($id, $person, $donation, 'person', $report);

	return $result;

} # End of person_donations.

# -----------------------------------------------

1;
