package App::Office::Contacts::Database::Library;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use DBI 'looks_like_number';

use Encode; # For decode().

use Moo;

extends 'App::Office::Contacts::Database::Base';

our $VERSION = '2.04';

# -----------------------------------------------

sub build_error_xml
{
	my($self, $error, $result) = @_;

	$self -> db -> logger -> log(debug => "Database::Library.build_error_xml($error, ...)");

	my(@msg);
	my($value);

	push @msg, {left => 'Field', right => 'Error'};

	for my $field ($result -> invalids)
	{
		$value = $result -> get_original_value($field) || '';

		$self -> db -> logger -> log(error => "Validation error. Field '$field' has an invalid value: $value");

		push @msg, {left => $field, right => "Invalid value: $value"};
	}

	for my $field ($result -> missings)
	{
		$self -> db -> logger -> log(error => "Validation error. Field '$field' is missing");

		push @msg, {left => $field, right => 'Missing value'};
	}

	my($html) = $self -> db -> templater -> render
	(
		'fancy.table.tx',
		{
			data => [@msg],
		}
	);

	return
qq|<response>
	<error>Error: $error</error>
	<html><![CDATA[$html]]></html>
</response>
|;

} # End of build_error_xml.

# -----------------------------------------------

sub build_ok_xml
{
	my($self, $html) = @_;

	$self -> db -> logger -> log(debug => 'Database::Library.build_ok_xml(...)');

	return
qq|<response>
	<error></error>
	<html><![CDATA[$html]]></html>
</response>
|;

} # End of build_ok_xml.

# -----------------------------------------------

sub build_simple_error_xml
{
	my($self, $error, $html) = @_;

	$self -> db -> logger -> log(debug => "Database::Library.build_simple_error_xml($error, ...)");

	return
qq|<response>
	<error>Error: $error</error>
	<html><![CDATA[$html]]></html>
</response>
|;

} # End of build_simple_error_xml.

# -----------------------------------------------

sub count_reports
{
	my($self)   = @_;
	my($result) = $self -> db -> simple -> query('select count(*) from reports')
					|| die $self -> db -> simple -> error;

	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of count_reports.

# -----------------------------------------------

sub decode_hashref_list
{
	my($self, @list) = @_;
	@list            = () if ($#list < 0);

	my(@result);

	for my $item (@list)
	{
		$$item{$_} = decode('utf-8', $$item{$_} || '') for keys %$item;

		push @result, $item;
	}

	return [@result];

} # End of decode_hashref_list.

# -----------------------------------------------

sub decode_list
{
	my($self, @list) = @_;
	@list            = () if ($#list < 0);

	return [map{decode('utf-8', $_ || '')} @list];

} # End of decode_list.

# -----------------------------------------------

sub get_id2name_map
{
	my($self, $table_name) = @_;
	my($result) = $self -> db -> simple -> query("select id, name from $table_name")
					|| die $self -> db -> simple -> error;

	return $result -> map;

} # End of get_id2name.

# -----------------------------------------------

sub get_name2id_map
{
	my($self, $table_name) = @_;
	my($result) = $self -> db -> simple -> query("select name, id from $table_name")
					|| die $self -> db -> simple -> error;

	return $result -> map;

} # End of get_name2id_map.

# -----------------------------------------------

sub get_role_via_id
{
	my($self, $id) = @_;
	my($result)    = $self -> db -> simple -> query('select name from roles where id = ?', $id)
					|| die $self -> db -> simple -> error;

	# list() should never return undef here.
	# And list() implies there is just 1 matching record.

	return decode('utf-8', ($result -> list)[0] || '');

} # End of get_role_via_id.

# -----------------------------------------------

sub insert_hashref_get_id
{
	my($self, $table_name, $hashref) = @_;

	$self -> db -> simple -> insert($table_name, $hashref)
		|| die $self -> db -> simple -> error;

	return $self -> db -> simple -> last_insert_id(undef, undef, $table_name, undef);

} # End of insert_hashref_get_id.

# --------------------------------------------------

sub validate_id
{
	my($self, $table_name, $id) = @_;
	my($result) = $self -> db -> simple -> query("select id from $table_name where id = ?", $id)
					|| die $self -> db -> simple -> error;

	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of validate_id.

# --------------------------------------------------

sub validate_name
{
	my($self, $table_name, $name) = @_;
	my($result) = $self -> db -> simple -> query("select id from $table_name where name = ?", $name)
					|| die $self -> db -> simple -> error;

	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of validate_name.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::Library - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class is a L<Moo>-based object with these attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 build_error_xml($error, $result)

Builds XML for an Ajax response.

Parameters:

=over 4

=item o $error => $string

This is a string to display on the status line.

This method prepends 'Error: ' to $error, since that is what the Javascript looks for.

=item o $result => An object of type L<Data::Verifier::Result>

=back

=head2 build_ok_xml($html)

Builds XML for an Ajax response.

$html is the HTML to display.

=head2 build_simple_error_xml($error, $html)

Builds XML for an Ajax response. Parameters:

=over 4

=item o $error => $string

This is a string to appear in the status line

This method prepends 'Error: ' to $error, since that is what the Javascript looks for.

=item o $html is a string to appear in the result div

The name of this result div varies between applications.

For L<App::Office::Contacts::Import>, it is C<import_div>.

=back

=head2 count_reports()

Returns a count of the number of records in the 'reports' table.

=head2 decode_hashref_list(@list)

utf8-decodes the values in a list of hashrefs.

=head2 decode_list(@list)

utf8-decodes a list.

=head2 get_id2name_map($table_name)

Returns a hashref (for menus) in the form {$id => $name, ...}.

=head2 get_name2id_map($table_name)

Returns a hashref in the form {$name => $id, ...}.

=head2 get_role_via_id($id)

Returns the name of the role with the given $id.

=head2 insert_hashref_get_id($table_name, $hashref)

Inserts $hashref into $table_name, and returns the id of the new record.

=head2 validate_id($table_name, $id)

Checks if the $table_name contains $id in the primary key column.

=head2 validate_name($table_name, $name)

Checks if the $table_name contains $name in the column called 'name'.

=head1 FAQ

See L<App::Office::Contacts/FAQ>.

=head1 Support

See L<App::Office::Contacts/Support>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
