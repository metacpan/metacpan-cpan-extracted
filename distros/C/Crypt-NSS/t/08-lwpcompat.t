#!/usr/bin/perl

use lib "t/lib";
use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Test::Crypt::NSS::SelfServ;
use LWP::Simple;
use Net::HTTPS;

use Crypt::NSS config_dir => "db", cipher_suite => "US";

local @Net::HTTPS::ISA = qw(Net::NSS::SSL::LWPCompat Net::HTTP::Methods);

start_ssl_server(config_dir => "db", port => 4435, password => "crypt-nss", require_cert => 1);

local $Crypt::NSS::PKCS11::DefaultPinArg = "crypt-nss";

local $Net::NSS::SSL::DefaultClientCertHook = sub {
    my ($sock, $arg) = @_;

    ok(1, "Called certificate hook");

    my $cert = Crypt::NSS::PKCS11->find_cert_by_nickname("127.0.0.1", $sock->get_pkcs11_pin_arg);
    my $key = Crypt::NSS::PKCS11->find_key_by_any_cert($cert, $sock->get_pkcs11_pin_arg);
    
    return ($cert, $key);
};

my $content;
lives_ok {
    $content = get("https://127.0.0.1:4435");
};
ok($content);

stop_ssl_server();
