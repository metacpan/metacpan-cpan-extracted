# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-U2F.t'

#########################

use strict;
use warnings;
use constant TESTS => 18;

use Test::More tests => TESTS;

BEGIN {
    use_ok('Crypt::U2F::Server::Simple');
    use_ok('JSON::XS');
}

use Data::Dumper;

#########################

SKIP: {
    eval 'use Authen::U2F::Tester';
    if ( $@ or $Authen::U2F::Tester::VERSION < 0.02 ) {
        skip 'Authen::U2F::Tester ≥0.02 not installed, skipping', TESTS - 2;
    }

    my $crypter = Crypt::U2F::Server::Simple->new(
        appId  => 'Perl',
        origin => 'Perl'
    );
    ok( defined($crypter), 'new()' );

    if ( !defined($crypter) ) {
        diag( Crypt::U2F::Server::Simple::lastError() );
    }

    my $challenge = $crypter->registrationChallenge();
    my $parsed    = JSON::XS->new->utf8->decode($challenge);
    ok( defined($parsed), 'Parsing JSON string' );

    my $tester = Authen::U2F::Tester->new(
        certificate => Crypt::OpenSSL::X509->new_from_string(
            '-----BEGIN CERTIFICATE-----
MIIB6DCCAY6gAwIBAgIJAJKuutkN2sAfMAoGCCqGSM49BAMCME8xCzAJBgNVBAYT
AlVTMQ4wDAYDVQQIDAVUZXhhczEaMBgGA1UECgwRVW50cnVzdGVkIFUyRiBPcmcx
FDASBgNVBAMMC3ZpcnR1YWwtdTJmMB4XDTE4MDMyODIwMTc1OVoXDTI3MTIyNjIw
MTc1OVowTzELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRleGFzMRowGAYDVQQKDBFV
bnRydXN0ZWQgVTJGIE9yZzEUMBIGA1UEAwwLdmlydHVhbC11MmYwWTATBgcqhkjO
PQIBBggqhkjOPQMBBwNCAAQTij+9mI1FJdvKNHLeSQcOW4ob3prvIXuEGJMrQeJF
6OYcgwxrVqsmNMl5w45L7zx8ryovVOti/mtqkh2pQjtpo1MwUTAdBgNVHQ4EFgQU
QXKKf+rrZwA4WXDCU/Vebe4gYXEwHwYDVR0jBBgwFoAUQXKKf+rrZwA4WXDCU/Ve
be4gYXEwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBFAiEAiCdOEmw5
hknzHR1FoyFZKRrcJu17a1PGcqTFMJHTC70CIHeCZ8KVuuMIPjoofQd1l1E221rv
RJY1Oz1fUNbrIPsL
-----END CERTIFICATE-----', Crypt::OpenSSL::X509::FORMAT_PEM()
        ),
        key => Crypt::PK::ECC->new(
            \'-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIOdbZw1swQIL+RZoDQ9zwjWY5UjA1NO81WWjwbmznUbgoAoGCCqGSM49
AwEHoUQDQgAEE4o/vZiNRSXbyjRy3kkHDluKG96a7yF7hBiTK0HiRejmHIMMa1ar
JjTJecOOS+88fK8qL1TrYv5rapIdqUI7aQ==
-----END EC PRIVATE KEY-----'
        ),
    );

    my $r = $tester->register( 'Perl', $parsed->{challenge} );
    ok( $r->is_success, 'Good challenge value' ) or diag( $r->error_message );
    my $registrationData = encode_json(
        {
            clientData       => $r->client_data,
            errorCode        => 0,
            registrationData => $r->registration_data,
            version          => "U2F_V2"
        }
    );
    my ( $keyHandle, $userKey ) =
      $crypter->registrationVerify($registrationData);
    ok( ( $keyHandle and $userKey ), 'Key registered' )
      or diag( Crypt::U2F::Server::Simple::lastError() );

    undef $crypter;
    $crypter = Crypt::U2F::Server::Simple->new(
        appId     => 'Perl',
        origin    => 'Perl',
        keyHandle => $keyHandle,
        publicKey => $userKey,
    );
    ok( defined($crypter), 'new()' )
      or diag( Crypt::U2F::Server::Simple::lastError() );

    ok( $challenge = $crypter->authenticationChallenge(), 'Get auth challenge' )
      or diag( Crypt::U2F::Server::Simple::lastError() );

    $parsed = JSON::XS->new->utf8->decode($challenge);
    ok( defined($parsed),                   'Parsing JSON string' );
    ok( $parsed->{keyHandle} eq $keyHandle, 'KeyHandle match' );

    $r = $tester->sign( 'Perl', $parsed->{challenge}, $keyHandle );
    ok( $r->is_success, 'Good challenge value' ) or diag( $r->error_message );
    my $sign = encode_json(
        {
            signatureData => $r->signature_data,
            clientData    => $r->client_data,
            keyHandle     => $keyHandle,
            challenge     => $parsed->{challenge},
        }
    );

    if ( $Authen::U2F::Tester::VERSION >= 0.03 ) {
        ok( $crypter->authenticationVerify($sign), 'Good signature' )
          or diag( Crypt::U2F::Server::Simple::lastError() );
    }
    else {
        pass(
'Authen::2F::Tester-0.02 signatures are not recognized by Yubico library'
        );
    }
    undef $crypter;
    $crypter = Crypt::U2F::Server::Simple->new(
        appId     => 'Perl',
        origin    => 'Perl',
        keyHandle => $keyHandle,
        publicKey => $userKey,
    );
    ok( defined($crypter), 'new()' )
      or diag( Crypt::U2F::Server::Simple::lastError() );

    ok( $challenge = $crypter->authenticationChallenge(), 'Get auth challenge' )
      or diag( Crypt::U2F::Server::Simple::lastError() );

    $parsed = JSON::XS->new->utf8->decode($challenge);
    ok( defined($parsed),                   'Parsing JSON string' );
    ok( $parsed->{keyHandle} eq $keyHandle, 'KeyHandle match' );

    $r = $tester->sign( 'Perl', $parsed->{challenge} . 'xx', $keyHandle );
    ok( $r->is_success, 'Good challenge value' ) or diag( $r->error_message );
    $sign = encode_json(
        {
            signatureData => $r->signature_data,
            clientData    => $r->client_data,
            keyHandle     => $keyHandle,
            challenge     => $parsed->{challenge} . 'xxx',
        }
    );

    if ( $Authen::U2F::Tester::VERSION >= 0.03 ) {
        ok(
            (
                !$crypter->authenticationVerify($sign)
                  and Crypt::U2F::Server::Simple::lastError() =~ /challenge/i
            ),
            'Error detected'
        );
    }
    else {
        pass(
'Authen::2F::Tester-0.02 signatures are not recognized by Yubico library'
        );
    }
}
