package Courriel::Part::Multipart;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.49';

use Courriel::HeaderAttribute;
use Courriel::Helpers qw( unique_boundary );
use Courriel::Types qw( ArrayRef NonEmptyStr Part );
use Email::MessageID;

use Moose;
use MooseX::StrictConstructor;

with 'Courriel::Role::Part';

has preamble => (
    is        => 'ro',
    isa       => NonEmptyStr,
    predicate => 'has_preamble',
);

has epilogue => (
    is        => 'ro',
    isa       => NonEmptyStr,
    predicate => 'has_epilogue',
);

has _parts => (
    traits   => ['Array'],
    isa      => ArrayRef [Part],
    init_arg => 'parts',
    required => 1,
    handles  => {
        parts      => 'elements',
        part_count => 'count',
    },
);

sub BUILD {
    my $self = shift;
    my $p    = shift;

    my $boundary = delete $p->{boundary} // unique_boundary;
    my $existing = $self->content_type->attribute('boundary');

    ## no critic (Subroutines::ProtectPrivateSubs)
    $self->content_type->_set_attribute(
        boundary => Courriel::HeaderAttribute->new(
            name  => ( $existing ? $existing->name : 'boundary' ),
            value => $boundary,
        )
    );
    ## use critic

    $_->_set_container($self) for $self->parts;

    return;
}

sub is_attachment {0}
sub is_inline     {0}
sub is_multipart  {1}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _stream_content {
    my $self   = shift;
    my $output = shift;

    $output->( $self->preamble, $Courriel::Helpers::CRLF )
        if $self->has_preamble;

    for my $part ( $self->parts ) {
        $output->(
            $Courriel::Helpers::CRLF,
            '--',
            $self->boundary,
            $Courriel::Helpers::CRLF,
        );

        $part->stream_to( output => $output );
    }

    $output->(
        $Courriel::Helpers::CRLF,
        '--',
        $self->boundary,
        '--',
        $Courriel::Helpers::CRLF
    );

    $output->( $self->epilogue, $Courriel::Helpers::CRLF )
        if $self->has_epilogue;

    return;
}
## use critic

sub boundary {
    my $self = shift;

    return $self->content_type->attribute_value('boundary');
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A part which contains other parts

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::Part::Multipart - A part which contains other parts

=head1 VERSION

version 0.49

=head1 SYNOPSIS

  my $headers = $part->headers;
  my $ct = $part->content_type;

  for my $subpart ( $part->parts ) { ... }

=head1 DESCRIPTION

This class represents a multipart email part which contains other parts.

=head1 API

This class provides the following methods:

=head2 Courriel::Part::Multipart->new( ... )

This method creates a new part object. It accepts the following parameters:

=over 4

=item * parts

An array reference of part objects (either Single or Multipart). This is
required, but could be empty.

=item * content_type

A L<Courriel::Header::ContentType> object. This defaults to one with a mime
type of "multipart/mixed".

=item * boundary

The part boundary. If none is provided, a unique value will be generated.

=item * preamble

Content that appears before the first part boundary. This will be seen by email
clients that don't understand multipart messages.

=item * epilogue

Content that appears after the final part boundary. The spec allows for this,
but it's probably not very useful.

=item * headers

A L<Courriel::Headers> object containing headers for this part.

=back

=head2 $part->parts()

Returns an array (not a reference) of the parts this part contains.

=head2 $part->part_count()

Returns the number of parts this part contains.

=head2 $part->boundary()

Returns the part boundary.

=head2 $part->mime_type()

Returns the mime type for this part.

=head2 $part->content_type()

Returns the L<Courriel::Header::ContentType> object for this part.

=head2 $part->headers()

Returns the L<Courriel::Headers> object for this part.

=head2 $part->is_inline(), $part->is_attachment()

These methods always return false, but exist for the sake of providing a
consistent API between Single and Multipart part objects.

=head2 $part->is_multipart()

Returns true.

=head2 $part->preamble()

The preamble as passed to the constructor.

=head2 $part->epilogue()

The epilogue as passed to the constructor.

=head2 $part->container()

Returns the L<Courriel> or L<Courriel::Part::Multipart> object to which this
part belongs, if any. This is set when the part is added to another object.

=head2 $part->stream_to( output => $output )

This method will send the stringified part to the specified output. The output
can be a subroutine reference, a filehandle, or an object with a C<print()>
method. The output may be sent as a single string, as a list of strings, or via
multiple calls to the output.

=head2 $part->as_string()

Returns the part as a string, along with its headers. Lines will be terminated
with "\r\n".

=head1 ROLES

This class does the C<Courriel::Role::Part> and C<Courriel::Role::Streams>
roles.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Courriel/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Courriel can be found at L<https://github.com/houseabsolute/Courriel>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
