package Courriel::Header::Disposition;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.48';

use Courriel::Types qw( Bool Maybe NonEmptyStr );
use DateTime;
use DateTime::Format::Mail;

use Moose;
use MooseX::StrictConstructor;

extends 'Courriel::Header';

with 'Courriel::Role::HeaderWithAttributes' =>
    { main_value_key => 'disposition' };

has '+value' => (
    required => 0,
    lazy     => 1,
    builder  => 'as_header_value',
);

has disposition => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has is_inline => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->disposition() ne 'attachment' },
);

has is_attachment => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    default  => sub { !$_[0]->is_inline() },
);

has filename => (
    is       => 'ro',
    isa      => Maybe [NonEmptyStr],
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        exists $_[0]->_attributes()->{filename}
            ? $_[0]->_attributes()->{filename}->value()
            : undef;
    },
);

{
    my $parser = DateTime::Format::Mail->new( loose => 1 );
    for my $attr (qw( creation_datetime modification_datetime read_datetime ))
    {
        ( my $name_in_header = $attr ) =~ s/_/-/g;
        $name_in_header =~ s/datetime/date/;

        my $default = sub {
            my $attr = $_[0]->_attributes()->{$name_in_header};
            return unless $attr;

            my $dt = $parser->parse_datetime( $attr->value() );
            $dt->set_time_zone('UTC') if $dt;

            return $dt;
        };

        has $attr => (
            is       => 'ro',
            isa      => Maybe ['DateTime'],
            init_arg => undef,
            lazy     => 1,
            default  => $default,
        );
    }
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    $p->{name} = 'Content-Disposition' unless exists $p->{name};

    return $p;
};

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: The content disposition for an email part

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::Header::Disposition - The content disposition for an email part

=head1 VERSION

version 0.48

=head1 SYNOPSIS

    my $disp = $part->content_disposition();
    print $disp->is_inline();
    print $disp->is_attachment();
    print $disp->filename();

    my %attr = $disp->attributes();
    while ( my ( $k, $v ) = each %attr ) {
        print "$k => $v\n";
    }

=head1 DESCRIPTION

This class represents the contents of a "Content-Disposition" header attached
to an email part. Such headers indicate whether or not a part should be
considered an attachment or should be displayed to the user directly. This
header may also include information about the attachment's filename, creation
date, etc.

Here are some typical headers:

  Content-Disposition: inline

  Content-Disposition: multipart/alternative; boundary=abcdefghijk

  Content-Disposition: attachment; filename="Filename.jpg"

  Content-Disposition: attachment; filename="foo-bar.jpg";
    creation-date="Tue, 31 May 2011 09:41:13 -0700"

=head1 API

This class supports the following methods:

=head2 Courriel::Header::Disposition->new_from_value( ... )

This takes two parameters, C<name> and C<value>. The C<name> is optional, and
defaults to "Content-Disposition".

The C<value> is parsed and split up into the disposition and attributes.

=head2 Courriel::Header::Disposition->new( ... )

This method creates a new object. It accepts the following parameters:

=over 4

=item * name

This defaults to 'Content-Type'.

=item * value

This is the full header value.

=item * disposition

This should usually either be "inline" or "attachment".

In theory, the RFCs allow other values.

=item * attributes

A hash reference of attributes from the header, such as a filename, creation
date, size, etc. The keys are attribute names and the values can either be
strings or L<Courriel::HeaderAttribute> objects. Values which are strings will
be inflated into objects by the constructor.

This is optional, and can be an empty hash reference or omitted entirely.

=back

=head2 $ct->name()

The header name, usually "Content-Disposition".

=head2 $ct->value()

The raw header value.

=head2 $disp->disposition()

Returns the disposition value passed to the constructor.

=head2 $disp->is_inline()

Returns true if the disposition is not equal to "attachment".

=head2 $disp->is_attachment()

Returns true if the disposition is equal to "attachment".

=head2 $disp->filename()

Returns the filename found in the attributes, or C<undef>.

=head2 $disp->creation_datetime(), $disp->last_modified_datetime(), $disp->read_datetime()

These methods look for a corresponding attribute ("creation-date", etc.) and
return a L<DateTime> object representing that attribute's value, if it exists.

=head2 $disp->attributes()

Returns a hash (not a reference) of the attributes passed to the constructor.

Attributes are L<Courriel::HeaderAttribute> objects.

The keys of the hash are all lower case, though the original casing is
preserved in the C<name()> returned by the L<Courriel::HeaderAttribute>
object.

=head2 $disp->attribute($key)

Given a key, returns the named L<Courriel::HeaderAttribute> object. Obviously,
this value can be C<undef> if the attribute doesn't exist. Name lookup is
case-insensitive.

=head2 $disp->attribute_value($key)

Given a key, returns the named attribute's value as a string. Obviously, this
value can be C<undef> if the attribute doesn't exist. Name lookup is
case-insensitive.

The attribute is a L<Courriel::HeaderAttribute> object.

=head2 $disp->as_header_value()

Returns the object as a string suitable for a header value (but not folded).

=head1 EXTENDS

This class extends L<Courriel::Header>.

=head1 ROLES

This class does the C<Courriel::Role::HeaderWithAttributes> role.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Courriel/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Courriel can be found at L<https://github.com/houseabsolute/Courriel>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
