use 5.008001;
use strict;
use warnings;

package TestSCRAM;

use Encode qw/encode_utf8/;
use MIME::Base64 qw/decode_base64/;
use PBKDF2::Tiny qw/derive digest_fcn hmac/;

use base 'Exporter';
our @EXPORT = qw/get_client get_server get_cred check_proxy/;

my ( $sha1, $sha1_block ) = digest_fcn('SHA-1');

# username => [ base64-salt, password, iterations ]
# entry 'user' matches example from RFC 5802
my %CRED_INPUTS = (
    user                => [ 'QSXCR+Q6sek8bf92', 'pencil',                 4096 ],
    johndoe             => [ 'saltSALTsaltSALT', 'passPASSpass',           4096 ],
    "johnd\N{U+110B}oe" => [ 'salt',             "pass\N{U+110B}PASSpass", 4096 ],
);

# username => [ salt, stored key, server key, iterations ];
my %CRED;

for my $user ( keys %CRED_INPUTS ) {
    my ( $salt, $pw, $i ) = @{ $CRED_INPUTS{$user} };
    $salt = decode_base64($salt);
    my $salted_password = derive( 'SHA-1', encode_utf8($pw), $salt, $i );
    my $client_key = _hmac( $salted_password, "Client Key" );
    my $stored_key = $sha1->($client_key);
    my $server_key = _hmac( $salted_password, "Server Key" );
    $CRED{$user} = [ $salt, $stored_key, $server_key, $i ];
}

# username (can act as) authz_id
my %VALID_PROXY = (
    johndoe             => 'admin',
    "johnd\N{U+110B}oe" => "admi\N{U+110B}n"
);

sub _hmac {
    my ( $key, $data ) = @_;
    $key = $sha1->($key) if length($key) > $sha1_block;
    return hmac( $data, $key, $sha1, $sha1_block );
}

sub check_proxy {
    my ( $user, $authz ) = @_;
    return ( ( $VALID_PROXY{$user} || '' ) eq $authz );
}

sub get_cred {
    my $user = shift;
    return @{ $CRED{$user} || [] };
}

sub get_client {
    require Authen::SCRAM::Client;
    return Authen::SCRAM::Client->new( username => 'user', password => 'pencil', @_ );
}

sub get_server {
    require Authen::SCRAM::Server;
    return Authen::SCRAM::Server->new(
        credential_cb => \&get_cred,
        auth_proxy_cb => \&check_proxy,
        @_
    );
}

1;

