package Crypt::Age::Header;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: age file header parsing and generation

use Moo;
use Carp qw(croak);
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::Age::Stanza::X25519;
use namespace::clean;


use constant VERSION_LINE => "age-encryption.org/v1";

has stanzas => (
    is      => 'ro',
    default => sub { [] },
);


has mac => (
    is => 'rw',
);


sub create {
    my ($class, $file_key, $recipients) = @_;

    my @stanzas;
    for my $recipient (@$recipients) {
        if ($recipient =~ /^age1/) {
            push @stanzas, Crypt::Age::Stanza::X25519->wrap($file_key, $recipient);
        } else {
            croak "Unsupported recipient format: $recipient";
        }
    }

    my $header = $class->new(stanzas => \@stanzas);

    # Compute and set MAC
    my $header_bytes = $header->_header_bytes_for_mac;
    my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $header_bytes);
    $header->mac($mac);

    return $header;
}


sub to_string {
    my ($self) = @_;

    my @lines = (VERSION_LINE);

    for my $stanza (@{$self->stanzas}) {
        push @lines, $stanza->to_string;
    }

    # MAC line
    my $mac_b64 = Crypt::Age::Stanza::encode_base64_no_padding($self->mac);
    push @lines, "--- $mac_b64";

    return join("\n", @lines) . "\n";
}


sub _header_bytes_for_mac {
    my ($self) = @_;

    my @lines = (VERSION_LINE);

    for my $stanza (@{$self->stanzas}) {
        push @lines, $stanza->to_string;
    }

    # For MAC, we include everything up to but not including the MAC itself
    # The footer line is "---" (without the MAC)
    push @lines, "---";

    return join("\n", @lines);
}

sub parse {
    my ($class, $data_ref, $offset_ref) = @_;

    my $data = $$data_ref;
    my $pos = $$offset_ref // 0;

    # Find header end (the line starting with ---)
    my $header_end = index($data, "\n---", $pos);
    croak "Invalid age file: no header footer found" if $header_end < 0;

    # Extract header text
    my $header_text = substr($data, $pos, $header_end - $pos + 1);
    my @lines = split /\n/, $header_text;

    # Check version
    my $version_line = shift @lines;
    croak "Invalid age version: $version_line" unless $version_line eq VERSION_LINE;

    # Parse stanzas
    my @stanzas;
    while (@lines) {
        my $line = shift @lines;
        last if $line =~ /^---/;

        if ($line =~ /^-> (\S+)\s*(.*)/) {
            my $type = $1;
            my @args = split /\s+/, $2;

            # Read body lines
            my $body_b64 = '';
            while (@lines && $lines[0] !~ /^->/ && $lines[0] !~ /^---/) {
                my $body_line = shift @lines;
                $body_b64 .= $body_line;
                last if length($body_line) < 64;  # Short line ends body
            }

            my $body = Crypt::Age::Stanza::decode_base64_no_padding($body_b64);

            my $stanza_class = 'Crypt::Age::Stanza';
            if ($type eq 'X25519') {
                $stanza_class = 'Crypt::Age::Stanza::X25519';
            }

            push @stanzas, $stanza_class->new(
                type => $type,
                args => \@args,
                body => $body,
            );
        }
    }

    # Parse MAC line
    $pos = $header_end + 1;  # Position after the newline before ---
    my $footer_end = index($data, "\n", $pos);
    $footer_end = length($data) if $footer_end < 0;

    my $footer_line = substr($data, $pos, $footer_end - $pos);
    croak "Invalid footer: $footer_line" unless $footer_line =~ /^--- (\S+)$/;
    my $mac = Crypt::Age::Stanza::decode_base64_no_padding($1);

    # Update offset to point after header
    $$offset_ref = $footer_end + 1;

    return $class->new(
        stanzas => \@stanzas,
        mac     => $mac,
    );
}


sub verify_mac {
    my ($self, $file_key) = @_;

    my $header_bytes = $self->_header_bytes_for_mac;
    my $expected_mac = Crypt::Age::Primitives->compute_header_mac($file_key, $header_bytes);

    return $self->mac eq $expected_mac;
}


sub unwrap_file_key {
    my ($self, $identities) = @_;

    for my $identity (@$identities) {
        for my $stanza (@{$self->stanzas}) {
            if ($stanza->isa('Crypt::Age::Stanza::X25519') && $identity =~ /^AGE-SECRET-KEY-1/i) {
                my $file_key = $stanza->unwrap($identity);
                if (defined $file_key && $self->verify_mac($file_key)) {
                    return $file_key;
                }
            }
        }
    }

    croak "No matching identity found";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age::Header - age file header parsing and generation

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Crypt::Age::Header;

    # Create header for encryption
    my $header = Crypt::Age::Header->create($file_key, \@recipient_public_keys);
    my $header_text = $header->to_string;

    # Parse header during decryption
    my $offset = 0;
    my $header = Crypt::Age::Header->parse(\$ciphertext, \$offset);

    # Unwrap file key
    my $file_key = $header->unwrap_file_key(\@identity_secret_keys);

=head1 DESCRIPTION

This module handles parsing and generation of age file headers.

An age file header is a text section at the beginning of an age file that contains:

=over 4

=item * Version line (C<age-encryption.org/v1>)

=item * One or more recipient stanzas (each wrapping the file key)

=item * MAC footer (authenticates the header)

=back

The header format is:

    age-encryption.org/v1
    -> X25519 <base64-ephemeral-public-key>
    <base64-wrapped-file-key>
    --- <base64-mac>

This is an internal module used by L<Crypt::Age>.

=head2 stanzas

ArrayRef of L<Crypt::Age::Stanza> objects representing recipient stanzas.

Each stanza wraps the file key for one recipient.

=head2 mac

The header MAC as raw bytes (32 bytes).

Used to authenticate the header and verify that the correct file key was unwrapped.

=head2 create

    my $header = Crypt::Age::Header->create($file_key, \@recipients);

Creates a new header for encrypting to multiple recipients.

Parameters:

=over 4

=item * C<$file_key> - The 16-byte file key to wrap

=item * C<\@recipients> - ArrayRef of Bech32-encoded public keys (C<age1...>)

=back

Returns a L<Crypt::Age::Header> object with stanzas for each recipient and a
computed MAC.

=head2 to_string

    my $header_text = $header->to_string;

Serializes the header to text format.

Returns a string containing the version line, all stanzas, and the MAC footer,
suitable for writing to the beginning of an age file.

=head2 parse

    my $header = Crypt::Age::Header->parse(\$data, \$offset);

Parses an age header from encrypted data.

Parameters:

=over 4

=item * C<\$data> - ScalarRef to the complete age file data

=item * C<\$offset> - ScalarRef to offset, updated to point past the header

=back

Returns a L<Crypt::Age::Header> object. The C<$offset> is updated to point to
the start of the payload.

Dies if the header format is invalid.

=head2 verify_mac

    my $ok = $header->verify_mac($file_key);

Verifies that the header MAC is correct for the given file key.

Returns true if the MAC is valid, false otherwise. Used to confirm that the
correct file key was unwrapped from a stanza.

=head2 unwrap_file_key

    my $file_key = $header->unwrap_file_key(\@identities);

Attempts to unwrap the file key using one or more identities.

Parameters:

=over 4

=item * C<\@identities> - ArrayRef of Bech32-encoded secret keys (C<AGE-SECRET-KEY-1...>)

=back

Tries each identity against each stanza until one successfully unwraps the file
key and verifies the MAC. Returns the 16-byte file key.

Dies if no matching identity is found or if MAC verification fails.

=head1 SEE ALSO

=over 4

=item * L<Crypt::Age> - Main age encryption module

=item * L<Crypt::Age::Stanza> - Base stanza class

=item * L<Crypt::Age::Stanza::X25519> - X25519 recipient stanza

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
