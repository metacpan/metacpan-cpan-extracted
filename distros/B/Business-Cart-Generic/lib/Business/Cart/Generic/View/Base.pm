package Business::Cart::Generic::View::Base;

use strict;
use warnings;

use Moose;

use Text::Xslate 'mark_raw';

extends 'Business::Cart::Generic::Database::Base';

has config =>
(
 is       => 'ro',
 isa      => 'HashRef',
 required => 1,
);

has templater =>
(
 is       => 'ro',
 isa      => 'Text::Xslate',
 required => 1,
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub build_select
{
	my($self, $class_name, $default, $id_name, $column_list, $onchange) = @_;

	$self -> db -> logger -> log(debug => "build_select($class_name, $default)");

	$default     ||= 1;
	$id_name     ||= lc "${class_name}_id";
	$onchange    = $onchange ? qq|onchange="$onchange"| : '';
	$column_list ||= ['name'];
	my($option)  = $self -> db -> get_id2name_map($class_name, $column_list);

	return $self -> templater -> render
	(
	 'select.tx',
	 {
		 name     => $id_name,
		 onchange => mark_raw($onchange),
		 loop     =>
			 [map
				  {
					  {
						  default => $_ == $default ? 1 : 0,
						  name    => $$option{$_},
						  value   => $_,
					  };
				  } sort{$$option{$a} cmp $$option{$b} } keys %$option
			 ],
	 }
	);

} # End of build_select.

# -----------------------------------------------

sub build_special_select
{
	my($self, $map, $default, $id_name) = @_;

	$self -> db -> logger -> log(debug => 'build_special_select()');

	return $self -> templater -> render
	(
	 'select.tx',
	 {
		 name => $id_name,
		 loop =>
			 [map
				  {
					  {
						  default => $_ == $default ? 1 : 0,
						  name    => mark_raw($$map{$_}),
						  value   => $_,
					  };
				  } sort{$$map{$a} cmp $$map{$b} } keys %$map
			 ],
	 }
	);

} # End of build_special_select.

# -----------------------------------------------

sub format_errors
{
	my($self, $error) = @_;
	my($param) =
	{
		data => [],
	};

	my($s);

	for my $key (sort keys %$error)
	{
		$s = "$key: " . join(', ', @{$$error{$key} });

		push @{$$param{data} }, {td => mark_raw($s)};

		$self -> db -> logger -> log(debug => "Error. $s");
	}

	my($output) =
	{
		div     => 'order_message_div',
		content => $self -> templater -> render('error.tx', $param),
	};

	return JSON::XS -> new -> utf8 -> encode($output);

} # End of format_errors.

# -----------------------------------------------

sub format_note
{
	my($self, $note) = @_;
	my($param) =
	{
		data => [],
	};

	my($s);

	for my $key (sort keys %$note)
	{
		$s = "$key: " . join(', ', @{$$note{$key} });

		push @{$$param{data} }, {td => mark_raw($s)};

		$self -> db -> logger -> log(debug => "Error. $s");
	}

	my($output) =
	{
		div     => 'order_message_div',
		content => $self -> templater -> render('note.tx', $param),
	};

	return JSON::XS -> new -> utf8 -> encode($output);

} # End of format_note.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::View::Base> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Business::Cart::Generic::Database::Base>.

=head2 Using new()

This class is never used stand-alone. See e.g. L<Business::Cart::Generic::View> and L<Business::Cart::Generic::View::Order>.

C<new()> is called as C<< my($obj) = Business::Cart::Generic::View::Base -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::View::Base>. See L<Business::Cart::Generic::View>.

Key-value pairs accepted in the parameter list:

=over 4

=item o config => $config

Takes an object of type L<Business::Cart::Generic::Util::Config>.

This key => value pair is mandatory.

=item o templater => $templater

Takes a L<Text::Xslate> object.

This key => value pair is mandatory.

=back

These keys are also getter-type methods. config() returns a hashref, and templater() returns an object.

=head1 Methods

=head2 build_select($class_name, $default, $id_name, $column_list, $onchange)

Returns a block of HTML for a select statement, using the given parameters.

=head2 build_special_select($map, $default, $id_name)

Returns a block of HTML for a specialized select statement, using the given parameters.

=head2 format_errors($error)

$error is a hashref of (usually) error information. L<Business::Cart::Generic::Util::Validator> returns such a
hashref when errors are detected in user input.

Returns a JSON and utf8 encoded block of text (usually of error messages) suitable for sending to the client.

=head2 format_note($note)

$note is a hashref of information for the user.

Returns a JSON and utf8 encoded block of text suitable for sending to the client.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who chose to make osCommerce and PrestaShop, Zen Cart, etc, Open Source.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business::Cart::Generic>.

=head1 Author

L<Business::Cart::Generic> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
