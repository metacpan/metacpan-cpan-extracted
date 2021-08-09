package Courriel::Part::Single;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.49';

use Courriel::Header::Disposition;
use Courriel::Types qw( NonEmptyStr StringRef );
use Email::MIME::Encodings;
use Encode qw( decode encode );
use MIME::Base64      ();
use MIME::QuotedPrint ();

use Moose;
use MooseX::StrictConstructor;

with 'Courriel::Role::Part';

has content_ref => (
    is        => 'ro',
    isa       => StringRef,
    coerce    => 1,
    init_arg  => 'content',
    lazy      => 1,
    builder   => '_build_content_ref',
    predicate => '_has_content_ref',
);

has encoded_content_ref => (
    is        => 'ro',
    isa       => StringRef,
    coerce    => 1,
    init_arg  => 'encoded_content',
    lazy      => 1,
    builder   => '_build_encoded_content_ref',
    predicate => '_has_encoded_content_ref',
);

has disposition => (
    is        => 'ro',
    isa       => 'Courriel::Header::Disposition',
    lazy      => 1,
    builder   => '_build_disposition',
    predicate => '_has_disposition',
    handles   => [qw( is_attachment is_inline filename )],
);

has encoding => (
    is        => 'rw',
    writer    => '_set_encoding',
    isa       => NonEmptyStr,
    lazy      => 1,
    default   => '8bit',
    predicate => '_has_encoding',
);

sub BUILD {
    my $self = shift;

    unless ( $self->_has_content_ref || $self->_has_encoded_content_ref ) {
        die
            'You must provide a content or encoded_content parameter when constructing a Courriel::Part::Single object.';
    }

    if ( !$self->_has_encoding ) {
        my @enc = $self->headers->get('Content-Transfer-Encoding');

        $self->_set_encoding( $enc[0]->value )
            if @enc && $enc[0];
    }

    $self->_sync_headers_with_self;

    return;
}

after _set_headers => sub {
    my $self = shift;

    $self->_sync_headers_with_self;

    return;
};

sub _sync_headers_with_self {
    my $self = shift;

    $self->_maybe_set_disposition_in_headers;

    $self->headers->replace( 'Content-Transfer-Encoding' => $self->encoding );

    return;
}

sub _maybe_set_disposition_in_headers {
    my $self = shift;

    return unless $self->_has_disposition;

    $self->headers->replace( 'Content-Disposition' => $self->disposition );
}

{
    my $fake_disp = Courriel::Header::Disposition->new_from_value(
        name  => 'Content-Disposition',
        value => 'inline',
    );

    sub _build_disposition {
        my $self = shift;

        my @disp = $self->headers->get('Content-Disposition');
        if ( @disp > 1 ) {
            die
                'This email defines more than one Content-Disposition header.';
        }

        return $disp[0] // $fake_disp;
    }
}

sub is_multipart {0}

{
    my %unencoded = map { $_ => 1 } qw( 7bit 8bit binary );

    sub _build_content_ref {
        my $self = shift;

        my $encoding = $self->encoding;

        my $bytes
            = $unencoded{ lc $encoding }
            ? $self->encoded_content
            : Email::MIME::Encodings::decode(
            $encoding,
            $self->encoded_content,
            );

        return \$bytes if $self->content_type->is_binary;

        return \$bytes
            if lc $self->content_type->charset eq 'unknown-8bit';

        return \(
            decode(
                $self->content_type->charset,
                $bytes,
            )
        );
    }

    sub _build_encoded_content_ref {
        my $self = shift;

        my $encoding = $self->encoding;

        my $bytes = $self->content_type->is_binary ? $self->content : encode(
            $self->content_type->charset,
            $self->content,
        );

        return \$bytes if $unencoded{ lc $encoding };

        return \(
            Email::MIME::Encodings::encode(
                $encoding,
                $bytes,
            )
        );
    }
}

sub content {
    return ${ $_[0]->content_ref };
}

sub encoded_content {
    return ${ $_[0]->encoded_content_ref };
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _stream_content {
    my $self   = shift;
    my $output = shift;

    return $output->( $self->encoded_content );
}
## use critic

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A part which does not contain other parts, only content

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::Part::Single - A part which does not contain other parts, only content

=head1 VERSION

version 0.49

=head1 SYNOPSIS

  my $headers = $part->headers;
  my $ct = $part->content_type;

  my $content = $part->content;
  print ${$content};

=head1 DESCRIPTION

This class represents a single part that does not contain other parts, just
content.

=head1 API

This class provides the following methods:

=head2 Courriel::Part::Single->new( ... )

This method creates a new part object. It accepts the following parameters:

=over 4

=item * content

This can either be a string or a reference to a scalar. It should be a
character string, I<not> a byte string.

If you pass a reference, then the scalar underlying the reference may be
modified, so don't pass in something you don't want modified.

=item * encoded_content

This can either be a string or a reference to a scalar.

If you pass a reference, then the scalar underlying the reference may be
modified, so don't pass in something you don't want modified.

=item * content_type

A L<Courriel::Header::ContentType> object. This will default to one with the
mime type "text/plain".

=item * disposition

A L<Courriel::Header::Disposition> object representing this part's content
disposition. This will default to "inline" with no other attributes.

=item * encoding

The Content-Transfer-Encoding for this part. This defaults to the value found
in the part's headers, or "8bit" if no header is found.

=item * headers

A L<Courriel::Headers> object containing headers for this part.

=back

You must pass a C<content> or C<encoded_content> value when creating a new
part, but there's really no point in passing both.

It is strongly recommended that you pass a C<content> parameter and letting
this module do the encoding for you internally.

=head2 $part->content()

This returns returns the decoded content for the part. It will be in Perl's
native utf-8 encoding, decoded from whatever character set the content is in.

=head2 $part->encoded_content()

This returns returns the encoded content for the part.

=head2 $part->mime_type()

Returns the mime type for this part.

=head2 $part->has_charset()

Return true if the part has a charset defined. Binary attachments will usually
not have this defined.

=head2 $part->charset()

Returns the charset for this part.

=head2 $part->is_inline(), $part->is_attachment()

These methods return boolean values based on the part's content disposition.

=head2 $part->filename()

Returns the filename from the part's content disposition, if any.

=head2 $part->content_type()

Returns the L<Courriel::Header::ContentType> object for this part.

=head2 $part->disposition()

Returns the L<Courriel::Header::Disposition> object for this part.

=head2 $part->encoding()

Returns the encoding for the part.

=head2 $part->headers()

Returns the L<Courriel::Headers> object for this part.

=head2 $part->is_multipart()

Returns false.

=head2 $part->container()

Returns the L<Courriel> or L<Courriel::Part::Multipart> object to which this
part belongs, if any. This is set when the part is added to another object.

=head2 $part->content_ref()

This returns returns a reference to a scalar containing the decoded content for
the part.

=head2 $part->encoded_content_ref()

This returns returns a reference to a scalar containing the encoded content for
the part, without any decoding.

=head2 $part->as_string()

Returns the part as a string, along with its headers. Lines will be terminated
with "\r\n".

=head2 $part->stream_to( output => $output )

This method will send the stringified part to the specified output. The output
can be a subroutine reference, a filehandle, or an object with a C<print()>
method. The output may be sent as a single string, as a list of strings, or via
multiple calls to the output.

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
