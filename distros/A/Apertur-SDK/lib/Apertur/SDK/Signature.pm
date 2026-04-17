package Apertur::SDK::Signature;

use strict;
use warnings;

use Digest::SHA qw(hmac_sha256 hmac_sha256_hex);
use MIME::Base64 qw(encode_base64 decode_base64);

use Exporter 'import';
our @EXPORT_OK = qw(
    verify_webhook_signature
    verify_event_signature
    verify_svix_signature
);

sub verify_webhook_signature {
    my ($body, $signature, $secret) = @_;

    my $expected = hmac_sha256_hex($body, $secret);
    my $sig = $signature;
    $sig =~ s/^sha256=//;

    return _timing_safe_eq($expected, $sig);
}

sub verify_event_signature {
    my ($body, $timestamp, $signature, $secret) = @_;

    my $signature_base = "${timestamp}.${body}";
    my $expected = hmac_sha256_hex($signature_base, $secret);
    my $sig = $signature;
    $sig =~ s/^sha256=//;

    return _timing_safe_eq($expected, $sig);
}

sub verify_svix_signature {
    my ($body, $svix_id, $timestamp, $signature, $secret) = @_;

    my $signature_base = "${svix_id}.${timestamp}.${body}";
    my $secret_bytes = pack('H*', $secret);
    my $expected_bytes = hmac_sha256($signature_base, $secret_bytes);
    my $expected = encode_base64($expected_bytes, '');

    my $sig = $signature;
    $sig =~ s/^v1,//;

    my $sig_bytes   = decode_base64($sig);
    my $exp_bytes   = decode_base64($expected);

    return _timing_safe_eq_bytes($exp_bytes, $sig_bytes);
}

# Constant-time string comparison to prevent timing attacks.
sub _timing_safe_eq {
    my ($a, $b) = @_;
    return 0 if length($a) != length($b);
    my $result = 0;
    for my $i (0 .. length($a) - 1) {
        $result |= ord(substr($a, $i, 1)) ^ ord(substr($b, $i, 1));
    }
    return $result == 0;
}

# Constant-time byte string comparison.
sub _timing_safe_eq_bytes {
    my ($a, $b) = @_;
    return 0 if length($a) != length($b);
    my $result = 0;
    for my $i (0 .. length($a) - 1) {
        $result |= ord(substr($a, $i, 1)) ^ ord(substr($b, $i, 1));
    }
    return $result == 0;
}

1;

__END__

=head1 NAME

Apertur::SDK::Signature - Webhook signature verification

=head1 SYNOPSIS

    use Apertur::SDK::Signature qw(
        verify_webhook_signature
        verify_event_signature
        verify_svix_signature
    );

    # Image delivery webhook
    my $valid = verify_webhook_signature($body, $signature, $secret);

    # Event webhook (HMAC method)
    my $valid = verify_event_signature($body, $timestamp, $signature, $secret);

    # Event webhook (Svix method)
    my $valid = verify_svix_signature($body, $svix_id, $timestamp, $signature, $secret);

=head1 DESCRIPTION

Provides functions to verify webhook signatures sent by the Apertur API.
All comparisons use constant-time algorithms to prevent timing attacks.

=head1 FUNCTIONS

=over 4

=item B<verify_webhook_signature($body, $signature, $secret)>

Verifies an image delivery webhook. The signature is expected to be in
the format C<sha256=E<lt>hexE<gt>>.

=item B<verify_event_signature($body, $timestamp, $signature, $secret)>

Verifies an event webhook using the HMAC method. The signed payload is
C<${timestamp}.${body}>.

=item B<verify_svix_signature($body, $svix_id, $timestamp, $signature, $secret)>

Verifies an event webhook using the Svix method. The signed payload is
C<${svix_id}.${timestamp}.${body}> and the secret is hex-decoded before
use. The signature is expected in the format C<v1,E<lt>base64E<gt>>.

=back

=cut
