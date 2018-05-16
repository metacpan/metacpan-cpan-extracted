package Courriel::Headers;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.46';

use Courriel::Header;
use Courriel::Header::ContentType;
use Courriel::Header::Disposition;
use Courriel::Types
    qw( ArrayRef Defined HashRef HeaderArray NonEmptyStr Str Streamable StringRef );
use Encode qw( decode );
use MIME::Base64 qw( decode_base64 );
use MIME::QuotedPrint qw( decode_qp );
use Params::ValidationCompiler qw( validation_for );
use Scalar::Util qw( blessed reftype );

use Moose;
use MooseX::StrictConstructor;

with 'Courriel::Role::Streams' => { -exclude => ['stream_to'] };

has _headers => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => HeaderArray,
    default  => sub { [] },
    init_arg => 'headers',
    handles  => {
        headers => 'elements',
    },
);

# The _key_indices field, along with all the complicated code to
# get/add/remove headers below, is necessary because RFC 5322 says:
#
#   However, for the purposes of this specification, header fields SHOULD NOT
#   be reordered when a message is transported or transformed.  More
#   importantly, the trace header fields and resent header fields MUST NOT be
#   reordered, and SHOULD be kept in blocks prepended to the message.
#
# So we store headers as an array ref. When we add additional values for a
# header, we will put them after the last header of the same name in the array
# ref. If no such header exists yet, then we just put them at the end of the
# arrayref.

has _key_indices => (
    traits   => ['Hash'],
    isa      => HashRef [ ArrayRef [NonEmptyStr] ],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_key_indices',
    clearer  => '_clear_key_indices',
    handles  => {
        __key_indices_for => 'get',
    },
);

override BUILDARGS => sub {
    my $class = shift;

    my $p = super();

    return $p unless $p->{headers};

    # Could this be done as a coercion for the HeaderArray type? Maybe, but
    # it'd probably need structured types, which seems like as much of a
    # hassle as just doing this.
    if ( reftype( $p->{headers} ) eq 'ARRAY' ) {
        my $headers = $p->{headers};

        ## no critic (ControlStructures::ProhibitCStyleForLoops)
        for ( my $i = 1; $i < @{$headers}; $i += 2 ) {
            next if blessed( $headers->[ $i - 1 ] );

            my $name = $headers->[ $i - 1 ];

            next unless defined $name;

            $headers->[$i] = $class->_inflate_header( $name, $headers->[$i] );
        }
    }
    elsif ( reftype( $p->{headers} ) eq 'HASH' ) {
        for my $name ( keys %{ $p->{headers} } ) {
            next if blessed( $p->{headers}{$name} );

            $p->{headers}{$name}
                = $class->_inflate_header( $name, $p->{headers}{$name} );
        }
    }

    return $p;
};

sub _inflate_header {
    my $class = shift;
    my $name  = shift;
    my $value = shift;

    my ( $header_class, $method )
        = lc $name eq 'content-type'
        ? ( 'Courriel::Header::ContentType', 'new_from_value' )
        : lc $name eq 'content-disposition'
        ? ( 'Courriel::Header::Disposition', 'new_from_value' )
        : ( 'Courriel::Header', 'new' );

    return $header_class->$method(
        name  => $name,
        value => $value,
    );
}

sub _build_key_indices {
    my $self = shift;

    my $headers = $self->_headers;

    my %indices;
    ## no critic (ControlStructures::ProhibitCStyleForLoops)
    for ( my $i = 0; $i < @{$headers}; $i += 2 ) {
        push @{ $indices{ lc $headers->[$i] } }, $i + 1;
    }

    return \%indices;
}

{
    my $validator = validation_for(
        params => [ { type => NonEmptyStr } ],
    );

    sub get {
        my $self = shift;
        my ($name) = $validator->(@_);

        return @{ $self->_headers }[ $self->_key_indices_for($name) ];
    }
}

{
    my $validator = validation_for(
        params => [ { type => NonEmptyStr } ],
    );

    sub get_values {
        my $self = shift;
        my ($name) = $validator->(@_);

        return
            map { $_->value }
            @{ $self->_headers }[ $self->_key_indices_for($name) ];
    }
}

sub _key_indices_for {
    my $self = shift;
    my $name = shift;

    return @{ $self->__key_indices_for( lc $name ) || [] };
}

{
    my $validator = validation_for(
        params => [
            { type => NonEmptyStr },
            { type => Defined },
        ],
    );

    sub add {
        my $self = shift;
        my ( $name, $value ) = $validator->(@_);

        my $headers = $self->_headers;

        my $last_index = ( $self->_key_indices_for($name) )[-1];

        my $header
            = blessed($value)
            && $value->isa('Courriel::Header')
            ? $value
            : $self->_inflate_header( $name, $value );

        if ($last_index) {
            splice @{$headers}, $last_index + 1, 0, ( $name => $header );
        }
        else {
            push @{$headers}, ( $name => $header );
        }

        $self->_clear_key_indices;

        return;
    }
}

{
    my $validator = validation_for(
        params => [
            { type => NonEmptyStr },
            { type => Defined },
        ],
    );

    # Used to add things like Resent or Received headers

    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    sub unshift {
        my $self = shift;
        my ( $name, $value ) = $validator->(@_);

        my $headers = $self->_headers;

        my $header
            = blessed($value)
            && $value->isa('Courriel::Header')
            ? $value
            : $self->_inflate_header( $name, $value );

        unshift @{$headers}, ( $name => $header );

        return;
    }
}

{
    my $validator = validation_for(
        params => [
            { type => NonEmptyStr },
        ],
    );

    sub remove {
        my $self = shift;
        my ($name) = $validator->(@_);

        my $headers = $self->_headers;

        for my $idx ( reverse $self->_key_indices_for($name) ) {
            splice @{$headers}, $idx - 1, 2;
        }

        $self->_clear_key_indices;

        return;
    }
}

{
    my $validator = validation_for(
        params => [
            { type => NonEmptyStr },
            { type => Defined },
        ],
    );

    sub replace {
        my $self = shift;
        my ( $name, $value ) = $validator->(@_);

        $self->remove($name);
        $self->add( $name => $value );

        return;
    }
}

{
    my $horiz_text = qr/[^\x0a\x0d]/;
    my $horiz_ws   = qr/[ \t]/;
    my $line_re    = qr/
                      (?:
                          ([^\s:][^:\n\r]*)  # a header name
                          :                  # followed by a colon
                          $horiz_ws*
                          ($horiz_text*)     # header value - can be empty
                      )
                      |
                      $horiz_ws+(\S$horiz_text*)?      # continuation line
                     /x;

    my $validator = validation_for(
        params        => [ text => { type => StringRef } ],
        named_to_list => 1,
    );

    sub parse {
        my $class = shift;
        my ($text) = $validator->(@_);

        my @headers;

        $class->_maybe_fix_broken_headers($text);

        while ( ${$text} =~ /\G${line_re}$Courriel::Helpers::LINE_SEP_RE/gc )
        {
            if ( defined $1 ) {
                push @headers, $1, $2;
            }
            else {
                die
                    'Header text contains a continuation line before a header name has been seen.'
                    unless @headers;

                $headers[-1] //= q{};

                # RFC 5322 says:
                #
                #   Runs of FWS, comment, or CFWS that occur between lexical tokens in a
                #   structured header field are semantically interpreted as a single
                #   space character.
                $headers[-1] .= q{ } if length $headers[-1];
                $headers[-1] .= $3   if defined $3;
            }
        }

        my $pos = pos ${$text} // 0;
        if ( $pos != length ${$text} ) {
            my @lines = split $Courriel::Helpers::LINE_SEP_RE,
                substr( ${$text}, 0, $pos );
            my $count = ( scalar @lines ) + 1;

            my $line = ( split $Courriel::Helpers::LINE_SEP_RE, ${$text} )
                [ $count - 1 ];

            die defined $line
                ? "Found an unparseable chunk in the header text starting at line $count:\n  $line"
                : 'Could not parse headers at all';
        }

        ## no critic (ControlStructures::ProhibitCStyleForLoops)
        for ( my $i = 1; $i < @headers; $i += 2 ) {
            $headers[$i] = $class->_mime_decode( $headers[$i] );
        }

        return $class->new( headers => \@headers );
    }
}

sub _maybe_fix_broken_headers {
    my $class = shift;
    my $text  = shift;

    # Some broken email messages have a newline in the headers that isn't
    # acting as a continuation, it's just an arbitrary line break. See
    # t/data/stress-test/mbox_mime_applemail_1xb.txt
    ${$text}
        =~ s/$Courriel::Helpers::LINE_SEP_RE([^\s:][^:]+$Courriel::Helpers::LINE_SEP_RE)/$1/g;

    return;
}

{
    my $validator = validation_for(
        params => [
            output => { type => Streamable },
            skip   => {
                type => ArrayRef [NonEmptyStr], default => sub { [] }
            },
            charset => { type => NonEmptyStr, default => 'utf8' },
        ],
        named_to_list => 1,
    );

    sub stream_to {
        my $self = shift;
        my ( $output, $skip, $charset ) = $validator->(@_);

        my %skip = map { lc $_ => 1 } @{$skip};

        for my $header ( grep { blessed($_) } @{ $self->_headers } ) {
            next if $skip{ lc $header->name };

            $header->stream_to( charset => $charset, output => $output );
        }

        return;
    }
}

sub as_string {
    my $self = shift;

    my $string = q{};

    $self->stream_to( output => $self->_string_output( \$string ), @_ );

    return $string;
}

{
    my $mime_word = qr/
                      (?:
                          =\?                         # begin encoded word
                          (?<charset>[-0-9A-Za-z_]+)  # charset (encoding)
                          (?:\*[A-Za-z]{1,8}(?:-[A-Za-z]{1,8})*)? # language (RFC 2231)
                          \?
                          (?<encoding>[QqBb])         # encoding type
                          \?
                          (?<content>.*?)             # Base64-encoded contents
                          \?=                         # end encoded word
                          |
                          (?<unencoded>\S+)
                      )
                      (?<ws>[ \t]+)?
                      /x;

    sub _mime_decode {
        my $self = shift;
        my $text = shift;

        return $text unless $text =~ /=\?[\w-]+\?[BQ]\?/i;

        my @chunks;

        # If a MIME encoded word is followed by _another_ such word, we ignore any
        # intervening whitespace, otherwise we preserve the whitespace between a
        # MIME encoded word and an unencoded word. See RFC 2047 for details on
        # this.
        while ( $text =~ /\G$mime_word/g ) {
            if ( defined $+{charset} ) {
                push @chunks, {
                    content => $self->_decode_one_word(
                        @+{ 'charset', 'encoding', 'content' }
                    ),
                    ws      => $+{ws},
                    is_mime => 1,
                };
            }
            else {
                push @chunks, {
                    content => $+{unencoded},
                    ws      => $+{ws},
                    is_mime => 0,
                };
            }
        }

        my $result = q{};

        for my $i ( 0 .. $#chunks ) {
            $result .= $chunks[$i]{content};
            $result .= ( $chunks[$i]{ws} // q{} )
                unless $chunks[$i]{is_mime}
                && $chunks[ $i + 1 ]
                && $chunks[ $i + 1 ]{is_mime};
        }

        return $result;
    }
}

sub _decode_one_word {
    my $self     = shift;
    my $charset  = shift;
    my $encoding = shift;
    my $content  = shift;

    if ( uc $encoding eq 'B' ) {
        return decode( $charset, decode_base64($content) );
    }
    else {
        $content =~ tr/_/ /;
        return decode( $charset, decode_qp($content) );
    }
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: The headers for an email part

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::Headers - The headers for an email part

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    my $email = Courriel->parse( text => ... );
    my $headers = $email->headers;

    print "$_\n" for $headers->get('Received');

=head1 DESCRIPTION

This class represents the headers of an email.

Any sub part of an email can have its own headers, so every part has an
associated object representing its headers. This class makes no distinction
between top-level headers and headers for a sub part.

Each individual header name/value pair is represented internally by a
L<Courriel::Header> object. Some headers have their own special
subclass. These are:

=over 4

=item * Content-Type

This is stored as a L<Courriel::Header::ContentType> object.

=item * Content-Disposition

This is stored as a L<Courriel::Header::Disposition> object.

=back

=head1 API

This class supports the following methods:

=head2 Courriel::Headers->parse( ... )

This method creates a new object by parsing a string. It accepts the following
parameters:

=over 4

=item * text

The text to parse. This can either be a plain scalar or a reference to a
scalar. If you pass a reference, the underlying scalar may be modified.

=back

Header parsing unfolds folded headers, and decodes any MIME-encoded values as
described in RFC 2047. Parsing also decodes header attributes encoded as
described in RFC 2231.

=head2 Courriel::Headers->new( headers => [ ... ] )

This method creates a new object. It accepts one parameter, C<headers>, which
should be an array reference of header names and values.

A given header key can appear multiple times.

This object does not (yet, perhaps) enforce RFC restrictions on repetition of
certain headers.

Header order is preserved, per RFC 5322.

=head2 $headers->get($name)

Given a header name, this returns a list of the L<Courriel::Header> objects
found for the header. Each occurrence of the header is returned as a separate
object.

=head2 $headers->get_values($name)

Given a header name, this returns a list of the string values found for the
header. Each occurrence of the header is returned as a separate string.

=head2 $headers->add( $name => $value )

Given a header name and value, this adds the headers to the object. If any of
the headers already have values in the object, then new values are added after
the existing values, rather than at the end of headers.

The value can be provided as a string or a L<Courriel::Header> object.

=head2 $headers->unshift( $name => $value )

This is like C<add()>, but this pushes the headers onto the front of the
internal headers array. This is useful if you are adding "Received" headers,
which per RFC 5322, should always be added at the I<top> of the headers.

The value can be provided as a string or a L<Courriel::Header> object.

=head2 $headers->remove($name)

Given a header name, this removes all instances of that header from the object.

=head2 $headers->replace( $name => $value )

A shortcut for calling C<remove()> and C<add()>.

The value can be provided as a string or a L<Courriel::Header> object.

=head2 $headers->as_string( skip => ...., charset => ... )

This returns a string representing the headers in the object. The values will
be folded and/or MIME-encoded as needed.

The C<skip> parameter should be an array reference containing the name of
headers that should be skipped. This parameter is optional, and the default is
to include all headers.

The C<charset> parameter specifies what character set to use for MIME-encoding
non-ASCII values. This defaults to "utf8". The charset name must be one
recognized by the L<Encode> module.

MIME encoding is always done using the "B" (Base64) encoding, never the "Q"
encoding.

=head2 $headers->stream_to( output => $output, skip => ...., charset => ... )

This method will send the stringified headers to the specified output.

See the C<as_string()> method for documentation on the C<skip> and C<charset>
parameters.

=head1 ROLES

This class does the C<Courriel::Role::Streams> role.

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
