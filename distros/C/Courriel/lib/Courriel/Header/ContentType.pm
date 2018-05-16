package Courriel::Header::ContentType;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.46';

use Courriel::Types qw( Maybe NonEmptyStr );

use Moose;
use MooseX::StrictConstructor;

extends 'Courriel::Header';

with 'Courriel::Role::HeaderWithAttributes' => {
    main_value_key    => 'mime_type',
    main_value_method => '_original_mime_type',
};

has '+value' => (
    required => 0,
    lazy     => 1,
    builder  => 'as_header_value',
);

has '+name' => (
    default => 'Content-Type',
);

has mime_type => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has _original_mime_type => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has charset => (
    is       => 'ro',
    isa      => Maybe [NonEmptyStr],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_charset',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    $p->{name} = 'Content-Type' unless exists $p->{name};

    return unless defined $p->{mime_type};

    $p->{_original_mime_type} = $p->{mime_type};
    $p->{mime_type}           = lc $p->{mime_type};

    return $p;
};

sub _build_charset {
    my $self = shift;

    return unless exists $self->_attributes()->{charset};

    return $self->_attributes()->{charset}->value();
}

sub is_binary {
    my $self = shift;

    return defined $self->charset() && $self->charset() ne 'binary' ? 0 : 1;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: The content type for an email part

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::Header::ContentType - The content type for an email part

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    my $ct = $part->content_type();
    print $ct->mime_type();
    print $ct->charset();

    my %attr = $ct->attributes();
    while ( my ( $k, $v ) = each %attr ) {
        print "$k => $v\n";
    }

=head1 DESCRIPTION

This class represents the contents of a "Content-Type" header attached to an
email part. Such headers always include a mime type, and may also include
additional information such as a charset or other attributes.

Here are some typical headers:

  Content-Type: text/plain; charset=utf-8

  Content-Type: multipart/alternative; boundary=abcdefghijk

  Content-Type: image/jpeg; name="Filename.jpg"

=head1 API

This class supports the following methods:

=head2 Courriel::Header::ContentType->new_from_value( ... )

This takes two parameters, C<name> and C<value>. The C<name> is optional, and
defaults to "Content-Type".

The C<value> is parsed and split up into the mime type and attributes.

=head2 Courriel::Header::ContentType->new( ... )

This method creates a new object. It accepts the following parameters:

=over 4

=item * name

This defaults to 'Content-Type'.

=item * value

This is the full header value.

=item * mime_type

A string like "text/plain" or "multipart/alternative". This is required.

=item * attributes

A hash reference of attributes from the header, such as a boundary, charset,
etc. The keys are attribute names and the values can either be strings or
L<Courriel::HeaderAttribute> objects. Values which are strings will be
inflated into objects by the constructor.

This is optional, and can be an empty hash reference or omitted entirely.

=back

=head2 $ct->name()

The header name, usually "Content-Type".

=head2 $ct->value()

The raw header value.

=head2 $ct->mime_type()

Returns the mime type value passed to the constructor. However, this value
will be in all lower-case, regardless of the original casing passed to the
constructor.

=head2 $ct->charset()

Returns the charset for the content type, which will be the value found in the
C<attributes>, if one exists.

=head2 $ct->attributes()

Returns a hash (not a reference) of the attributes passed to the constructor.

Attributes are L<Courriel::HeaderAttribute> objects.

The keys of the hash are all lower case, though the original casing is
preserved in the C<name()> returned by the L<Courriel::HeaderAttribute>
object.

=head2 $ct->is_binary()

Returns true unless the attachment looks like text data. Currently, this means
that is has a charset defined and the charset is not "binary".

=head2 $ct->attribute($key)

Given a key, returns the named L<Courriel::HeaderAttribute> object. Obviously,
this value can be C<undef> if the attribute doesn't exist. Name lookup is
case-insensitive.

=head2 $ct->attribute_value($key)

Given a key, returns the named attribute's value as a string. Obviously, this
value can be C<undef> if the attribute doesn't exist. Name lookup is
case-insensitive.

The attribute is a L<Courriel::HeaderAttribute> object.

=head2 $ct->as_header_value()

Returns the object as a string suitable for a header value (but not
folded). Note that this uses the original casing of the mime type as passed to
the constructor.

=head1 EXTENDS

This class extends L<Courriel::Header>.

=head1 ROLES

This class does the C<Courriel::Role::HeaderWithAttributes> role.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Courriel> or via email to L<bug-courriel@rt.cpan.org|mailto:bug-courriel@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Courriel can be found at L<https://github.com/houseabsolute/Courriel>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
