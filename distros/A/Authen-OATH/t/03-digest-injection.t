use strict;
use warnings;

use Authen::OATH ();
use Test::More tests => 2;

our $PWNED = 0;
my $payload = q{Digest::SHA; $main::PWNED = 1; #};

my $oath = Authen::OATH->new( digest => $payload );
eval { $oath->totp( 'a' x 16 ) };

like( $@, qr/Invalid digest module name/, 'malicious digest is rejected' );
is( $PWNED, 0, 'injected code did not execute' );
