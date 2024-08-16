#!perl -w
use strict;
use Auth::GoogleAuthenticator;

my $auth = Auth::GoogleAuthenticator->new( secret => 'test@example.com');
print "Registration key " . $auth->registration_key() . "\n";
print "Expected OTP value " . $auth->totp() . "\n";
if( my $user_input = shift ) {
    my $verified = $auth->verify( $user_input ) ? 'verified' : 'not verified';
    print "$verified\n";
};
