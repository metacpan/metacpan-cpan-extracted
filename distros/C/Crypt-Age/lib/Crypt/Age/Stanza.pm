package Crypt::Age::Stanza;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Base class for age recipient stanzas

use Moo;
use Carp qw(croak);
use MIME::Base64 qw(encode_base64 decode_base64);
use namespace::clean;


has type => (
    is       => 'ro',
    required => 1,
);


has args => (
    is      => 'ro',
    default => sub { [] },
);


has body => (
    is      => 'ro',
    default => '',
);


sub encode_body_base64 {
    my ($self) = @_;
    return encode_base64_no_padding($self->body);
}

sub encode_base64_no_padding {
    my ($data) = @_;
    my $encoded = encode_base64($data, '');
    $encoded =~ s/=+$//;  # Remove padding
    return $encoded;
}

sub decode_base64_no_padding {
    my ($encoded) = @_;
    # Add padding back if needed
    my $pad = (4 - length($encoded) % 4) % 4;
    $encoded .= '=' x $pad;
    return decode_base64($encoded);
}

sub to_string {
    my ($self) = @_;

    my @parts = ('->', $self->type, @{$self->args});
    my $header_line = join(' ', @parts);

    my $body_b64 = encode_base64_no_padding($self->body);

    # Split into 64-char lines
    my @lines = ($header_line);
    while (length($body_b64) > 64) {
        push @lines, substr($body_b64, 0, 64, '');
    }
    push @lines, $body_b64;  # Last line (may be empty for exact multiple of 64)

    return join("\n", @lines);
}


sub to_bytes_for_mac {
    my ($self) = @_;
    # For MAC computation, stanzas are serialized as in the header
    return $self->to_string . "\n";
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age::Stanza - Base class for age recipient stanzas

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Crypt::Age::Stanza;

    # Create a stanza
    my $stanza = Crypt::Age::Stanza->new(
        type => 'X25519',
        args => ['base64-encoded-ephemeral-key'],
        body => $wrapped_file_key_bytes,
    );

    # Serialize to string
    my $text = $stanza->to_string;
    # -> X25519 base64-encoded-ephemeral-key
    # base64-wrapped-file-key

=head1 DESCRIPTION

This is the base class for age recipient stanzas.

A stanza represents one way to unwrap the file key. Each recipient in an age
file gets their own stanza. The stanza contains the information needed to
unwrap the file key if you have the corresponding private identity.

Stanzas have three parts:

=over 4

=item * C<type> - The recipient type (e.g., C<X25519>, C<scrypt>)

=item * C<args> - Type-specific arguments (e.g., ephemeral public key)

=item * C<body> - The wrapped file key (base64-encoded in the file)

=back

The stanza format in an age file is:

    -> type arg1 arg2 ...
    base64-wrapped-key-line1
    base64-wrapped-key-line2
    ...

Subclasses like L<Crypt::Age::Stanza::X25519> implement the actual wrapping and
unwrapping logic for specific recipient types.

=head2 type

The stanza type (e.g., C<X25519>, C<scrypt>).

Required.

=head2 args

ArrayRef of type-specific arguments.

For X25519 stanzas, this is the base64-encoded ephemeral public key.

=head2 body

The wrapped file key as raw bytes.

This is base64-encoded when serialized to the age file format.

=head2 to_string

    my $text = $stanza->to_string;

Serializes the stanza to age file format.

Returns a multi-line string with the stanza header (C<-E<gt> type args...>) and
base64-encoded body wrapped at 64 characters per line.

=head1 FUNCTIONS

=head2 encode_base64_no_padding

    my $encoded = Crypt::Age::Stanza::encode_base64_no_padding($bytes);

Encodes bytes to base64 without padding (no trailing C<=> characters).

This is the encoding used for all base64 in the age format.

=head2 decode_base64_no_padding

    my $bytes = Crypt::Age::Stanza::decode_base64_no_padding($encoded);

Decodes base64 without padding.

Automatically adds back the padding before decoding.

=head1 SEE ALSO

=over 4

=item * L<Crypt::Age> - Main age encryption module

=item * L<Crypt::Age::Header> - Header parsing and generation

=item * L<Crypt::Age::Stanza::X25519> - X25519 recipient stanza implementation

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-crypt-age/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
