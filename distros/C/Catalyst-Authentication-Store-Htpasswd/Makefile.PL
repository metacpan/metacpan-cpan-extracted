use strict;
use inc::Module::Install 0.87;

name 'Catalyst-Authentication-Store-Htpasswd';
all_from 'lib/Catalyst/Authentication/Store/Htpasswd.pm';

requires 'Catalyst::Plugin::Authentication' => '0.10006';
requires 'Authen::Htpasswd' => '0.13';
requires 'Class::Accessor::Fast';
requires 'Crypt::PasswdMD5';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::use::ok';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Authentication-Store-Htpasswd/1.000/trunk/';

WriteAll;  
