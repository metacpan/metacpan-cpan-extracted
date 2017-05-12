package App::Office::Contacts::View::Base;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use DateTime;

use Lingua::ENG::Inflect 'PL';

use Moo;

use Text::Xslate 'mark_raw';

extends 'App::Office::Contacts::Database::Base';

has view =>
(
	default  => sub{return ''},
	is       => 'ro',
	#isa     => 'App::Office::Contacts::View',
	required => 1,
);

my $email_phone_count = 4;
our $VERSION          = '2.04';

# -----------------------------------------------

sub build_email_menus
{
	my($self, $prefix, $email_araref) = @_;
	$email_araref = [sort{$$a{email}{address} cmp $$b{email}{address} } grep{$$_{email}{address} } @$email_araref];

	$self -> db -> logger -> log(debug => 'View::Base.build_email_menus');

	my($email_type)  = $self -> get_menu_data('email_address_types');

	my($default);
	my(@email_type_menu);

	for my $i (1 .. $email_phone_count)
	{
		$default = ($i - 1) <= $#$email_araref ? $$email_araref[$i - 1]{email}{type_id} : 1;

		push @email_type_menu, $self -> build_menu("${prefix}_email_address_type_id_$i", $email_type, $default);
	}

	return $self -> db -> templater -> render
	(
		'email.phone.tx',
		{
			list =>
			[
				map
				{
					{
						id        => "${prefix}_email_address_$_",
						prompt    => "Email $_",
						type_menu => mark_raw($email_type_menu[$_ - 1]),
						value     => $$email_araref[$_ - 1]{email}{address},
					}
				} 1 .. $email_phone_count
			],
		}
	);

} # End of build_email_menus.

# -----------------------------------------------

sub build_menu
{
	my($self, $name, $item, $default) = @_;

	$self -> db -> logger -> log(debug => "View::Base.build_menu($name, ...)");

	$default ||= 1;

	return $self -> db -> templater -> render
	(
		'menu.tx',
		{
			list =>
			[
				map
				{
					{
						key      => $$item[$_]{key},
						selected => ($$item[$_]{key} == $default) ? 'selected=selected' : '',
						value    => $$item[$_]{value},
					}
				} 0 .. $#$item
			],
			name => $name,
		}
	);

} # End of build_menu.

# -----------------------------------------------

sub build_phone_menus
{
	my($self, $prefix, $phone_araref) = @_;
	$phone_araref = [sort{$$a{phone}{number} cmp $$b{phone}{number} } grep{$$_{phone}{number} } @$phone_araref];

	$self -> db -> logger -> log(debug => "View::Base.build_phone_menus($prefix)");

	my($phone_type)  = $self -> get_menu_data('phone_number_types');

	my($default);
	my(@phone_type_menu);

	for my $i (1 .. $email_phone_count)
	{
		$default = ($i - 1) <= $#$phone_araref ? $$phone_araref[$i - 1]{phone}{type_id} : 1;

		push @phone_type_menu, $self -> build_menu("${prefix}_phone_number_type_id_$i", $phone_type, $default);
	}

	return $self -> db -> templater -> render
	(
		'email.phone.tx',
		{
			list =>
			[
				map
				{
					{
						id        => "${prefix}_phone_number_$_",
						prompt    => "Phone $_",
						type_menu => mark_raw($phone_type_menu[$_ - 1]),
						value     => $$phone_araref[$_ - 1]{phone}{number},
					}
				} 1 .. $email_phone_count
			],
		}
	);

} # End of build_phone_menus.

# -----------------------------------------------

sub build_simple_menu
{
	my($self, $prefix, $subject, $default) = @_;
	$default ||= 1;
	$prefix  = length($prefix) > 0 ? "${prefix}_" : '';

	$self -> db -> logger -> log(debug => "View::Base.build_simple_menu($prefix, $subject, $default)");

	return $self -> build_menu("${prefix}${subject}_id", $self -> get_menu_data(PL($subject) ), $default);

} # End of build_simple_menu.

# -----------------------------------------------

sub format_timestamp
{
	my($self, $timestamp) = @_;
	my(@field)     = split(/[- :.]/, $timestamp);
	my($datestamp) = DateTime -> new
	(
	 year   => $field[0],
	 month  => $field[1],
	 day    => $field[2],
	 hour   => $field[3],
	 minute => $field[4],
	 second => $field[5],
	);

	return $datestamp -> strftime('%A, %e %B %Y %I:%M:%S %P');

} # End of format_timestamp.

# -----------------------------------------------

sub get_menu_data
{
	my($self, $table) = @_;

	$self -> db -> logger -> log(debug => "View::Base.get_menu_data($table)");

	my($result) = $self -> db -> simple -> query("select name, id from $table order by name")
					|| die $self -> db -> simple -> error;
	my(%data)   = $result -> map;

	# Since we don't use utf8 in menus, so we don't need to call decode('utf-8', ...).

	return [map{ {key => $data{$_}, value => $_} } sort keys %data];

} # End of get_menu_data.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View::Base - A web-based contacts manager

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

=item o view

Is an instance of L<App::Office::Contacts::View>, and must be passed in to new().

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 build_email_menus($prefix, $email_araref)

Build menus for an organization's or person's list of email addresses.

=head2 build_menu($name, $item, $default)

Builds a single menu.

=head2 build_phone_menus($prefix, $phone_araref)

Build menus for an organization's or person's list of phone numbers.

=head2 build_simple_menu($prefix, $subject, $default)

Builds a menu directly from a database table.

Calls build_menu().

=head2 format_timestamp($timestamp)

=head2 get_menu_data($table)

Reads a database table for data which can be used to populate a menu.

=head2 view()

Returns the instance of L<App::Office::Contacts::View> passed in to new().

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
