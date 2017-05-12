use strict;
use warnings;

use Test::More;

use Authen::SASL qw(Perl);
use MIME::Base64 qw(decode_base64);
use Authen::NTLM;

use constant HOST   => 'localhost';
use constant DOMAIN => 'domain';
use constant USER   => 'user';
use constant PASS   => 'pass';

use_ok('Authen::SASL::Perl::NTLM');

my $challenge =
  'TlRMTVNTUAACAAAABAAEADAAAAAFggEAQUJDREVGR0gAAAAAAAAAAAAAAAAAAAAA';

my $ntlm = Authen::NTLM->new(
    host     => HOST,
    user     => USER,
    password => PASS,
);
my $msg1 = $ntlm->challenge;
my $msg2 = $ntlm->challenge($challenge);

my $conn;

# basic tests
{
    my $sasl = new_ok(
        'Authen::SASL', [
            mechanism => 'NTLM',
            callback  => {
                user => USER,
                pass => PASS,
            },
        ]
    );

    $conn = $sasl->client_new( 'ldap', 'localhost' );

    isa_ok( $conn, 'Authen::SASL::Perl::NTLM' );

    is( $conn->mechanism, 'NTLM', 'conn mechanism' );

    is( $conn->client_start, q{}, 'client start' );
    ok( !$conn->is_success, 'needs step' );

    is( $conn->client_step(), decode_base64($msg1),
        'initial message is correct (from undef challenge string)' );
    ok( !$conn->is_success, 'still needs step' );

    is( $conn->client_step( decode_base64($challenge) ),
        decode_base64($msg2), 'challenge response is correct' );
    ok( $conn->is_success, 'success' );
}

# step 1 error is detected
{
    is( $conn->client_start, q{}, 'client restart' );
    ok( $conn->need_step, 'needs step' );

    is( $conn->client_step($challenge), q{}, 'empty response' );
    like( $conn->error, qr/type 1/, 'error is set' );
}

# empty challenge string for step 1 is accepted
{
    is( $conn->client_start, q{}, 'client restart' );
    ok( $conn->need_step, 'needs step' );

    is( $conn->client_step(''),
        decode_base64($msg1),
        'initial message is correct (from empty challenge string)' );
    ok( $conn->need_step, 'still needs step' );
}

# step 2 error is detected
{
    is( $conn->client_step(''), q{}, 'empty response' );
    like( $conn->error, qr/type 2/, 'error is set' );
}

# invalid step error is detected
{
    is( $conn->client_step($challenge), q{}, 'empty response' );
    like( $conn->error, qr/Invalid step/, 'error is set' );
}

# domain specified with user
{
    my $ntlm = Authen::NTLM->new(
        host     => HOST,
        domain   => DOMAIN,
        user     => USER,
        password => PASS,
    );
    my $msg1 = $ntlm->challenge;
    my $msg2 = $ntlm->challenge($challenge);

    my $sasl = new_ok(
        'Authen::SASL', [
            mechanism => 'NTLM',
            callback  => {
                user => ( DOMAIN . '\\' . USER ),
                pass => PASS,
            },
        ]
    );

    my $conn = $sasl->client_new( 'ldap', 'localhost' );

    is( $conn->client_start, q{}, 'client_start' );

    ok( $msg1, 'initial message has a response' );

    is( $conn->client_step(''), decode_base64($msg1), 'initial message' );

    is( $conn->client_step( decode_base64($challenge) ),
        decode_base64($msg2), 'challenge response' );
}

done_testing;
