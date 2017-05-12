#!/usr/bin/perl

use lib "t/lib";
use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Test::Crypt::NSS::SelfServ;
use LWP::Simple;
use Net::HTTPS;

use Crypt::NSS config_dir => "db", cipher_suite => "US";

local @Net::HTTPS::ISA = qw(Net::NSS::SSL::LWPCompat Net::HTTP::Methods);

start_ssl_server(config_dir => "db", port => 4438, password => "crypt-nss", nickname => "invalid");

local $Crypt::NSS::PKCS11::DefaultPinArg = "crypt-nss";
local $Net::NSS::SSL::DefaultVerifyCertHook = "built-in-ignore";

my $content;
lives_ok {
    $content = get("https://127.0.0.1:4438");
};
ok($content);
stop_ssl_server();
