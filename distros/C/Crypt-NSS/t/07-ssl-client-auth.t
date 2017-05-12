#!/usr/bin/perl

use lib "t/lib";
use strict;
use warnings;

use Test::More tests => 5;
use Test::Crypt::NSS::SelfServ;

use Crypt::NSS config_dir => "db", cipher_suite => "US";

start_ssl_server(config_dir => "db", port => 4434, password => "crypt-nss", require_cert => 1);

my $socket = Net::NSS::SSL->create_socket("tcp");
$socket->set_option(Blocking => 1);
$socket->import_into_ssl_layer();
$socket->set_URL("127.0.0.1");
$socket->set_pkcs11_pin_arg("crypt-nss");

$socket->set_client_certificate_hook(sub {
    my ($self, $nickname) = @_;
    my ($cert, $key);

    is ($$self, $$socket, "Passed socket is correct");
    is ($nickname, "127.0.0.1", "Got expected nickname");
    
    $cert = Crypt::NSS::PKCS11->find_cert_by_nickname($nickname, $self->get_pkcs11_pin_arg);
    ok($cert, "Found cert");
    $key = Crypt::NSS::PKCS11->find_key_by_any_cert($cert, $self->get_pkcs11_pin_arg);
    ok($key, "Found key");
    
    return ($cert, $key);
}, "127.0.0.1");

$socket->connect("127.0.0.1", 4434);

$socket->write("GET / HTTP/1.0\n\n\n\n");

my $buffer;
my $reply = "";
while ($socket->read($buffer) > 0) { $reply .= $buffer; }
ok($reply, "Got data so auth worked");
$socket->close();

stop_ssl_server();

