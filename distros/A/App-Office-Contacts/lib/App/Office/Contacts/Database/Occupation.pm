package App::Office::Contacts::Database::Occupation;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Encode; # For decode().

use Moo;

extends 'App::Office::Contacts::Database::Base';

our $VERSION = '2.04';

# --------------------------------------------------

sub add
{
	my($self, $occupation) = @_;

	$self -> db -> logger -> log(debug => 'Entered Database::Occupation.add()');
	$self -> save_occupation_record('add', $occupation);

} # End of add.

# -----------------------------------------------

sub delete
{
	my($self, $occupation_id) = @_;

	$self -> db -> logger -> log(debug => "Entered Database::Occupation.delete($occupation_id)");

	my($table_name) = 'occupations';

	$self -> db -> simple -> delete($table_name, {id => $occupation_id})
		|| die $self -> db -> simple -> error;

} # End of delete.

# -----------------------------------------------

sub get_occupation_title_via_id
{
	my($self, $id) = @_;
	my($result)    = $self -> db -> simple -> query('select name from occupation_titles where id = ?', $id)
		|| die $self -> db -> simple -> error;

	# Since only 1 field is utf8, we just call decode('utf-8', ...) below,
	# rather than calling $self -> db -> library -> decode_list(...).
	# And list() implies there is just 1 matching record.

	return decode('utf-8', ($result -> list)[0] || '');

} # End of get_occupation_title_via_id.

# -----------------------------------------------

sub get_occupation_via_id
{
	my($self, $occupation) = @_;

	$self -> db -> logger -> log(debug => 'Entered Database::Occupation.get_occupation_via_id(...)');

	my($organization_name) = $self -> db -> organization -> get_organization_name($$occupation{organization_id});
	my($occupation_title)  = $self -> get_occupation_title_via_id($$occupation{occupation_title_id});

	return
	{
		occupation_title  => $occupation_title,
		organization_id   => $$occupation{organization_id},
		organization_name => $organization_name,
		person_id         => $$occupation{person_id},
	};

} # End of get_occupation_via_id.

# -----------------------------------------------

sub get_occupation_via_organization
{
	my($self, $organization_id) = @_;

	$self -> db -> logger -> log(debug => "Entered Database::Occupation.get_occupation_via_organization($organization_id)");

	my($result) = $self -> db -> simple -> query('select * from occupations where organization_id = ?', $organization_id)
					|| die $self -> db -> simple -> error;

	# The columns in the occupations table are all integers, so we don't need to call decode('utf-8', $x).

	return [$result -> hashes];

} # End of get_occupation_via_organization.

# -----------------------------------------------

sub get_occupation_via_person
{
	my($self, $person_id) = @_;

	$self -> db -> logger -> log(debug => "Entered Database::Occupation.get_occupation_via_person($person_id)");

	my($result) = $self -> db -> simple -> query('select * from occupations where person_id = ?', $person_id)
					|| die $self -> db -> simple -> error;

	# The columns in the occupations table are all integers, so we don't need to call decode('utf-8', $x).

	return [$result -> hashes];

} # End of get_occupation_via_person.

# --------------------------------------------------

sub save_occupation_record
{
	my($self, $context, $occupation) = @_;

	$self -> db -> logger -> log(debug => "Entered Database::Occupation.save_occupation_record($context, ...)");

	my(@field) = (qw/creator_id occupation_title_id organization_id person_id/);
	my($data)  = {};
	my(%id)    =
	(
	 creator          => 1,
	 occupation_title => 1,
	 organization     => 1,
	 person           => 1,
	);

	my($field_name);

	for (@field)
	{
		if ($id{$_})
		{
			$field_name = "${_}_id";
		}
		else
		{
			$field_name = $_;
		}

		$$data{$field_name} = $$occupation{$_};
	}

	my($table_name) = 'occupations';

	if ($context eq 'add')
	{
		$$occupation{id} = $$data{id} = $self -> db -> library -> insert_hashref_get_id($table_name, $data);
	}
	else
	{
		$self -> db -> simple -> update($table_name, $data, {id => $$occupation{id} })
			|| die $self -> db -> simple -> error;
	}

} # End of save_occupation_record.

# --------------------------------------------------

sub save_occupation_title
{
	my($self, $title) = @_;
	my($uc_title)     = encode('utf-8', uc decode('utf-8', $title) );

	$self -> db -> logger -> log(debug => "Entered Database::Occupation.save_occupation_title($title)");
	$self -> db -> simple -> insert('occupation_titles', {name => $title, upper_name => $uc_title})
		|| die $self -> db -> simple -> error;

} # End of save_occupation_title.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::Occupation - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

This module extends L<App::Office::Contacts::Database::Base>, with these attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 add($occupation)

Adds the occupation to the I<occupations> table.

=head2 delete($occupation_id)

Deletes the occupation from the I<occupations> table.

=head2 get_occupation_title_via_id($id)

Returns the occupation title with the given $id.

=head2 get_occupation_via_id($occupation)

Returns a hashref for the occupation with the given $id. Keys in this hashref are:

=over 4

=item o occupation_title

=item o organization_id

=item o organization_name

=item o person_id

=back

=head2 get_occupation_via_organization($organization_id)

Returns an arrayref of hashrefs where the occupation has the given $organization_id.

Keys in the hashref are column names from the I<occupations> table.

=head2 get_occupation_via_person($person_id)

Returns an arrayref of hashrefs where the occupation has the given $person_id.

Keys in the hashref are column names from the I<occupations> table.

=head2 save_occupation_record($context, $occupation)

Saves the given $occupation to the I<occupations> table. $context is 'add'.

=head2 save_occupation_title($title)

Saves the given $title to the I<occupation_titles> table.

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
