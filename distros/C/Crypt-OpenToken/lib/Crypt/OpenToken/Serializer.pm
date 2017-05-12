package Crypt::OpenToken::Serializer;

use strict;
use warnings;

our $WS   = qr/[\t ]/;      # WS, as per OpenToken spec (just tab and space)
our $CRLF = qr/[\r\n]/;     # CRLF, as per OpenToken spec

sub thaw {
    my $str = shift;
    my %data;

    while ($str) {
        my ($key, $val);
        my ($quote, $remainder);

        ($key, $remainder) = ($str =~ /^$WS*(\S+)$WS*=$WS*(.*)$/s);

        if ($remainder =~ /^['"]/) {
            ($quote, $val, $remainder)
                = ($remainder =~ /^(['"])(.*?)(?<!\\)\1$WS*?$CRLF+(.*)/s);
            $val =~ s/\\(['"])/$1/g;
        }
        else {
            ($val, $remainder) = split /$CRLF+/, $remainder, 2;
        }
        $str = $remainder;

        if (exists $data{$key}) {
            $data{$key} = [
                (ref($data{$key}) ? @{ $data{$key} } : $data{$key}),
                $val,
            ];
        }
        else {
            $data{$key} = $val;
        }
    }
    return %data;
}

sub freeze {
    my (%data) = @_;
    my $str;

    foreach my $key (sort keys %data) {
        my $val  = $data{$key};
        my @vals = ref($val) eq 'ARRAY' ? @{$val} : ($val);
        foreach my $v (@vals) {
            $v = '' unless (defined $v);
            if ($v =~ /\W/) {
                $v =~ s/(['"])/\\$1/g;
                $v = "'" . $v . "'";
            }
            $str .= "$key = $v\n";
        }
    }

    return $str;
}

1;

=head1 NAME

Crypt::OpenToken::Serializer - Serialize payloads for OpenTokens

=head1 SYNOPSYS

  use Crypt::OpenToken::Serializer;

  $payload = Crypt::OpenToken::Serializer::freeze(%data);

  %data = Crypt::OpenToken::Serializer::thaw($payload);

=head1 DESCRIPTION

This module implements the serialization routine described in the OpenToken
specification for generating the payload format.

Highlights:

=over

=item *

A line-based format in the form of "key = value".

=item *

Within quoted-strings, B<both> double and single quotes must be escaped by a
preceding backslash.

=item *

Encoded with UTF-8 and is guaranteed to support the transport of multi-byte
characters.

=item *

Key names might not be unique.  OpenToken supports multiple values for a key
name by simply adding another key-value pair.

=item *

Key names are case-sensitive.  It is RECOMMENDED that all key names be
lowercase and use hyphens to separate "words".

=back

=head1 METHODS

=over

=item Crypt::OpenToken::Serializer::thaw($string)

Thaws the given serialzed data, returning a hash of data back to the caller.

If the data contained any repeating keys, those are represented in the hash as
having an ARRAYREF as a value.

=item Crypt::OpenToken::Serializer::freeze(%data)

Freezes the given data, returning a serialized string back to the caller.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT & LICENSE

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=cut
