package Chandra::Socket::Token;

use strict;
use warnings;

our $VERSION = '0.21';

require Chandra;

1;

__END__

=head1 NAME

Chandra::Socket::Token - Token management with rotation and expiry

=head1 SYNOPSIS

    use Chandra::Socket::Token;

    my $tm = Chandra::Socket::Token->new(
        ttl      => 3600,    # Token expires after 1 hour (seconds)
        rotation => 1800,    # Rotate every 30 minutes
        grace    => 60,      # Old token valid for 60s after rotation
        length   => 32,      # Token length in bytes (default 32)
    );

    my $token = $tm->current;
    my $valid = $tm->validate($token);

    $tm->rotate;

    # Old token still valid during grace period
    $tm->validate($token);   # true (within grace)

    # Info hash
    my $info = $tm->info;

=head1 DESCRIPTION

Chandra::Socket::Token manages cryptographic token generation, validation,
rotation and expiry for the Chandra Socket IPC system.

Tokens are generated from C</dev/urandom> (with a C<rand()> fallback) and
represented as hex-encoded strings.

=head1 METHODS

=head2 new(%opts)

Create a new token manager. Options:

=over 4

=item ttl => $seconds

Token lifetime. Default 3600 (1 hour).

=item rotation => $seconds

Rotation interval. Default 1800 (30 minutes).

=item grace => $seconds

Grace period after rotation during which the old token is still accepted.
Default 60.

=item length => $bytes

Token length in bytes (hex output is 2x this). Default 32.

=back

=head2 generate

Generate and return a new random token (does not affect manager state).

=head2 current

Return the current active token.

=head2 previous

Return the previous token (during grace period), or undef.

=head2 validate($token)

Return 1 if the token matches current or previous (during grace), 0 otherwise.

=head2 rotate

Force a token rotation. Current token becomes previous with grace period.

=head2 rotation_due

Return 1 if the rotation interval has elapsed.

=head2 expired

Return 1 if the token has exceeded its TTL.

=head2 in_grace

Return 1 if currently within a grace period after rotation.

=head2 info

Return a hashref with token state: current, previous, created_at,
expires_at, rotation_at, grace_until.

=head2 on_rotate($coderef)

Register a callback fired on each rotation, receiving the new token.

=head2 ttl

Return the configured TTL.

=head2 rotation_interval

Return the configured rotation interval.

=head2 grace_period

Return the configured grace period.

=cut
