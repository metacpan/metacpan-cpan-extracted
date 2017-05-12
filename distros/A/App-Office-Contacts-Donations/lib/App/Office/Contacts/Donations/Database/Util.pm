package App::Office::Contacts::Donations::Database::Util;

use Moose;

extends 'App::Office::Contacts::Database::Util';

use namespace::autoclean;

our $VERSION = '1.10';

# -----------------------------------------------

sub get_currencies
{
	my($self) = @_;

	return $self -> select_map('select name, id from currencies');

} # End of get_currencies.

# -----------------------------------------------

sub get_currency_id_via_code
{
	my($self, $code) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from currencies where code = ?', {}, $code);

	return $id ? $$id{'id'} : 0;

} # End of get_currency_id_via_code.

# -----------------------------------------------

sub get_currency_code_via_id
{
	my($self, $id) = @_;
	my($name) = $self -> db -> dbh -> selectrow_hashref('select code from currencies where id = ?', {}, $id);

	return $$name{'code'};

} # End of get_currency_code_via_iid.

# -----------------------------------------------

sub get_currency_name_via_id
{
	my($self, $id) = @_;
	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from currencies where id = ?', {}, $id);

	return $$name{'name'};

} # End of get_currency_name_via_iid.

# -----------------------------------------------

sub get_donation_motive_name_via_id
{
	my($self, $id) = @_;
	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from donation_motives where id = ?', {}, $id);

	return $$name{'name'};

} # End of get_donation_motive_name_via_iid.

# -----------------------------------------------

sub get_donation_project_name_via_id
{
	my($self, $id) = @_;
	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from donation_projects where id = ?', {}, $id);

	return $$name{'name'};

} # End of get_donation_project_name_via_iid.

# -----------------------------------------------

sub get_donation_motives
{
	my($self) = @_;

	return $self -> select_map('select name, id from donation_motives');

} # End of get_donation_motives.

# -----------------------------------------------

sub get_donation_projects
{
	my($self) = @_;

	return $self -> select_map('select name, id from donation_projects');

} # End of get_donation_projects.

# --------------------------------------------------

sub validate_currency
{
	my($self, $value) = @_;

	return 1;

} # End of validate_currency.

# --------------------------------------------------

sub validate_donation_motive
{
	my($self, $value) = @_;

	return 1;

} # End of validate_donation_motive.

# --------------------------------------------------

sub validate_donation_project
{
	my($self, $value) = @_;

	return 1;

} # End of validate_donation_project.

# --------------------------------------------------

sub validate_report
{
	my($self, $value) = @_;
	my($id)           = $self -> db -> dbh -> selectrow_hashref('select id from reports where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_report.

# --------------------------------------------------

sub validate_report_entity
{
	my($self, $value) = @_;
	my($id)           = $self -> db -> dbh -> selectrow_hashref('select id from report_entities where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_report_entity.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
