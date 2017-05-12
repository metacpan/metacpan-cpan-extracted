package Courriel::Header;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Courriel::Helpers qw( fold_header );
use Courriel::Types qw( NonEmptyStr Str Streamable );
use Email::Address::List;
use Encode qw( encode find_encoding );
use MIME::Base64 qw( encode_base64 );
use Params::ValidationCompiler qw( validation_for );

use Moose;
use MooseX::StrictConstructor;

with 'Courriel::Role::Streams' => { -exclude => ['stream_to'] };

has name => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has value => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

{
    my $validator = validation_for(
        params => [
            charset => { type => NonEmptyStr, default => 'utf8' },
            output  => { type => Streamable },
        ],
        named_to_list => 1,
    );

    sub stream_to {
        my $self = shift;
        my ( $charset, $output ) = $validator->(@_);

        my $string = $self->name;
        $string .= ': ';

        $string .= $self->_maybe_encoded_value($charset);

        $output->( fold_header($string) );

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
    # RFC 2047 - An 'encoded-word' MUST NOT be used in a Received header
    # field.
    my %never_encode       = map { lc $_ => 1 } qw( Received );
    my %contains_addresses = map { lc $_ => 1 } qw( CC From To );

    # XXX - this really isn't very correct. Only certain types of values (per RFC
    # 2047) can be encoded, not just any random text. I'm not sure how best to
    # handle this. If we parsed an email that encoded stuff that shouldn't be
    # encoded, what should we do? At the very least, we should add some checks to
    # Courriel::Builder to ensure that people don't try to create an email with
    # non-ASCII in certain parts of fields (like in email addresses).
    sub _maybe_encoded_value {
        my $self    = shift;
        my $charset = shift;

        return $self->value
            if $never_encode{ lc $self->name };

        return $self->_encoded_address_list($charset)
            if $contains_addresses{ lc $self->name };

        return $self->_encode_string( $self->value, $charset );
    }
}

sub _encoded_address_list {
    my $self    = shift;
    my $charset = shift;

    my @elements;
    my @group;
    for my $parsed ( Email::Address::List->parse( $self->value ) ) {
        my $push_to = @group ? \@group : \@elements;
        ## no critic (ControlStructures::ProhibitCascadingIfElse)
        if ( $parsed->{type} eq 'group start' ) {
            @group = $parsed->{value} . ':';
        }
        elsif ( $parsed->{type} eq 'group end' ) {
            my $group = join ', ', @group;
            $group .= ';';
            push @elements, $group;
            @group = ();
        }
        elsif ( $parsed->{type} eq 'unknown' ) {
            push @{$push_to},
                $self->_encode_string( $parsed->{value}, $charset );
        }
        elsif ( $parsed->{type} eq 'mailbox' ) {
            push @{$push_to},
                $self->_maybe_encoded_address( $parsed->{value}, $charset );
        }
    }

    return join ', ', @elements;
}

sub _maybe_encoded_address {
    my $self    = shift;
    my $address = shift;
    my $charset = shift;

    my $encoded = q{};

    my $phrase = $address->phrase;
    if ( defined $phrase && length $phrase ) {
        my $enc_phrase = $self->_encode_string( $phrase, $charset );

        # If the phrase wasn't encoded then we can make it a quoted-word, if
        # it was encoded then it cannot be wrapped in quotes per RFC 2047.
        if ( $enc_phrase ne $phrase ) {
            $encoded .= $enc_phrase;
        }
        else {
            $encoded .= q{"} . $phrase . q{"};
        }
        $encoded .= q{ };
    }

    $encoded .= '<' . $address->address . '>';

    my $comment = $address->comment;
    if ( defined $comment && length $comment ) {
        $encoded .= '(' . $self->_encode_string( $comment, $charset ) . ')';
    }

    return $encoded;
}

{
    my $header_chunk = qr/
                             (?:
                                ^
                             |
                                 (?<ascii>[\x21-\x7e]+)   # printable ASCII (excluding space, \x20)
                             |
                                 (?<non_ascii>\S+)        # anything that's not space
                             )
                             (?:
                                 (?<ws>\s+)
                             |
                                 $
                             )
                         /x;

    sub _encode_string {
        my $self    = shift;
        my $string  = shift;
        my $charset = shift;

        my @chunks;
        while ( $string =~ /\G$header_chunk/g ) {
            push @chunks, {%+};
        }

        my @encoded;
        for my $i ( 0 .. $#chunks ) {
            if ( defined $chunks[$i]->{non_ascii} ) {
                my $to_encode
                    = $chunks[ $i + 1 ]
                    && defined $chunks[ $i + 1 ]{non_ascii}
                    ? $chunks[$i]{non_ascii} . ( $chunks[$i]{ws} // q{} )
                    : $chunks[$i]{non_ascii};

                push @encoded, $self->_mime_encode( $to_encode, $charset );
                push @encoded, q{ } if $chunks[ $i + 1 ];
            }
            else {
                push @encoded,
                    ( $chunks[$i]{ascii} // q{} )
                    . ( $chunks[$i]{ws}  // q{} );
            }
        }

        return join q{}, @encoded;
    }
}

sub _mime_encode {
    my $self    = shift;
    my $text    = shift;
    my $charset = find_encoding(shift)->mime_name;

    my $head = '=?' . $charset . '?B?';
    my $tail = '?=';

    my $base_length = 75 - ( length($head) + length($tail) );

    # This code is copied from Mail::Message::Field::Full in the Mail-Box
    # distro.
    my $real_length = int( $base_length / 4 ) * 3;

    my @result;
    my $chunk = q{};
    while ( length( my $chr = substr( $text, 0, 1, q{} ) ) ) {
        my $chr = encode( $charset, $chr, 0 );

        if ( length($chunk) + length($chr) > $real_length ) {
            push @result, $head . encode_base64( $chunk, q{} ) . $tail;
            $chunk = q{};
        }

        $chunk .= $chr;
    }

    push @result, $head . encode_base64( $chunk, q{} ) . $tail
        if length $chunk;

    return join q{ }, @result;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A single header's name and value

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::Header - A single header's name and value

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  my $subject = $headers->get('subject');
  print $subject->value;

=head1 DESCRIPTION

This class represents a single header, which consists of a name and value.

=head1 API

This class supports the following methods:

=head1 Courriel::Header->new( ... )

This method requires two attributes, C<name> and C<value>. Both must be
strings. The C<name> cannot be empty, but the C<value> can.

=head2 $header->name()

The header name as passed to the constructor.

=head2 $header->value()

The header value as passed to the constructor.

=head2 $header->as_string( charset => $charset )

Returns the header name and value with any necessary MIME encoding and folding.

The C<charset> parameter specifies what character set to use for MIME-encoding
non-ASCII values. This defaults to "utf8". The charset name must be one
recognized by the L<Encode> module.

=head2 $header->stream_to( output => $output, charset => ... )

This method will send the stringified header to the specified output. The
output can be a subroutine reference, a filehandle, or an object with a
C<print()> method. The output may be sent as a single string, as a list of
strings, or via multiple calls to the output.

See the C<as_string()> method for documentation on the C<charset> parameter.

=head1 ROLES

This class does the C<Courriel::Role::Streams> role.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Courriel>
(or L<bug-courriel@rt.cpan.org|mailto:bug-courriel@rt.cpan.org>).

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
