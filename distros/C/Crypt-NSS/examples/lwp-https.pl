#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple;
use Net::HTTPS;
use Crypt::NSS config_dir => "db", cipher_suite => "US";

@Net::HTTPS::ISA = qw(Net::NSS::SSL::LWPCompat Net::HTTP::Methods);

local $Crypt::NSS::PKCS11::DefaultPinArg = "crypt-nss";

my $content = get("https://www.mozilla.org");

print $content;