#!/usr/bin/perl

use 5.008001;

package #
	Template::Plugin::JSON;

our $AUTHORITY = 'cpan:JWRIGHT';
our $ALT = 'Moo';

use Types::Standard ();
use Carp ();
use JSON ();

use Alt::Template::Plugin::JSON::Moo;


use Moo;
use namespace::clean;

extends qw(Template::Plugin);

has context => (
	isa => Types::Standard::Object,
	is  => "ro",
	weak_ref => 1,
);

has json_converter => (
	isa => Types::Standard::Object,
	is  => "lazy",
	lazy_build => 1,
);

has json_args => (
	isa => Types::Standard::HashRef,
	is  => "ro",
	default => sub { {} },
);

sub BUILDARGS {
	my ( $class, $c, @args ) = @_;


	if ( @args == 1 and not ref $args[0] ) {
		warn "Single argument form is deprecated, this module always uses JSON/JSON::XS now";
	}

	my $args = ref $args[0] ? $args[0] : {};

	return { %$args, context => $c, json_args => $args };
}


sub _build_json_converter {
	my $self = shift;

	my $json = JSON->new->allow_nonref(1);

	my $args = $self->json_args;

	for my $method (keys %$args) {
		if ( $json->can($method) ) {
			$json->$method( $args->{$method} );
		}
	}

	return $json;
}

sub json {
	my ( $self, $value ) = @_;

	$self->json_converter->encode($value);
}

sub json_decode {
	my ( $self, $value ) = @_;

	$self->json_converter->decode($value);
}

sub BUILD {
	my $self = shift;
	$self->context->define_vmethod( $_ => json => sub { $self->json(@_) } ) for qw(hash list scalar);
}

no Moo;

__PACKAGE__;

__END__

=pod

=head1 NAME

Template::Plugin::JSON - Adds a .json vmethod for all TT values.

=head1 SYNOPSIS

	[% USE JSON ( pretty => 1 ) %];

	<script type="text/javascript">

		var foo = [% foo.json %];

	</script>

	or read in JSON

	[% USE JSON %]
	[% data = JSON.json_decode(json) %]
	[% data.thing %]

=head1 DESCRIPTION

This plugin provides a C<.json> vmethod to all value types when loaded. You
can also decode a json string back to a data structure.

It will load the L<JSON> module (you probably want L<JSON::XS> installed for
automatic speed ups).

Any options on the USE line are passed through to the JSON object, much like L<JSON/to_json>.

=head1 SEE ALSO

L<JSON>, L<Template::Plugin>

=head1 VERSION CONTROL

L<https://github.com/neilb/Template-Plugin-JSON>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006, 2008 Infinity Interactive, Yuval Kogman.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

