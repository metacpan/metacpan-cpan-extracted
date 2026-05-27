use Test2::V0;

use Authen::OATH ();

our $PWNED = 0;
my $payload = q{Digest::SHA; $main::PWNED = 1; #};

my $oath = Authen::OATH->new( digest => $payload );

like(
    dies { $oath->totp( 'a' x 16 ) },
    qr/Invalid digest module name/,
    'malicious digest is rejected'
);
is( $PWNED, 0, 'injected code did not execute' );

done_testing;
