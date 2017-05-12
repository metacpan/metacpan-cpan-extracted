#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => "Server sockets are not implemented yet";
use Test::Exception;

use Crypt::NSS config_dir => "db", cipher_suite => "US";
use Crypt::NSS::Constants qw(:ssl);

use constant DB_PASSWORD => "crypt-nss";

#Crypt::NSS::SSL->config_server_session_cache({});

#for (@{Crypt::NSS::SSL->_get_implemented_cipher_ids()}) {
#    Crypt::NSS::SSL->set_cipher($_, 0);
#}

Crypt::NSS::SSL->set_cipher(SSL_RSA_WITH_NULL_MD5, 1);

my $server = Net::NSS::SSL->create_socket("tcp");

$server->set_option("Blocking" => 1);
$server->bind("127.0.0.1", 10000);
$server->listen();

$server->import_into_ssl_layer();
$server->set_option(SSL_SECURITY, SSL_OPTION_ENABLED);
$server->set_option(SSL_ENABLE_SSL3, SSL_OPTION_ENABLED);
$server->set_option(SSL_ENABLE_SSL2, SSL_OPTION_DISABLED);

my $cert = Crypt::NSS::PKCS11->find_cert_by_nickname("127.0.0.1", DB_PASSWORD);
my $key = Crypt::NSS::PKCS11->find_key_by_any_cert($cert, DB_PASSWORD);

$server->configure_as_server($cert, $key);

while((my $client = $server->accept())) {
    $client->set_option(Blocking => 1);
    $client->reset_handshake(1);
    my ($buffer, $request) = "" x 2;
    while($client->read($buffer) > 0) {
        $request .= $buffer;
    }
    print STDERR "Got request: $request\n";
    $client->close();
}