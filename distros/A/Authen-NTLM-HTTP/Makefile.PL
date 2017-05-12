#!/usr/bin/env perl
use inc::Module::Install 0.91;
use strict;
use warnings;

name 'Authen-NTLM-HTTP';
all_from 'lib/Authen/NTLM/HTTP.pm';

requires 'MIME::Base64';

requires 'Crypt::DES_PP' => '1.00';
recommends 'Crypt::DES' => '2.03';

requires 'Digest::Perl::MD4' => '1.0';
recommends 'Digest::MD4' => '1.1';

test_requires 'Test';

license 'perl';

WriteAll;

