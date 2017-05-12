use strict;
use warnings;
use inc::Module::Install 0.87;

name 'Catalyst-Model-PayPal-IPN';
all_from 'lib/Catalyst/Model/PayPal/IPN.pm';

requires 'Catalyst::Runtime' => '5.7006';
requires 'Moose' => '0.20';
requires 'namespace::clean' => '0.04';
requires 'Business::PayPal::IPN';
requires 'Crypt::SSLeay'; # should be installed by IPN but isn't always

features('Form Encryption' => [ -default => 0, 'Business::PayPal::EWP']);

if(-e 'MANIFEST.SKIP') {
    system("pod2text lib/Catalyst/Model/PayPal/IPN.pm > README");
}

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Model-PayPal-IPN/';

WriteAll;
