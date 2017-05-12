use strict;
use inc::Module::Install;

name           'Authen-Simple';
all_from       'lib/Authen/Simple.pm';
readme_from    'lib/Authen/Simple.pm';
repository     'http://github.com/chansen/p5-authen-simple';

requires       'Class::Accessor::Fast'    => 0;
requires       'Class::Data::Inheritable' => 0; 
requires       'Crypt::PasswdMD5'         => 0; # Authen::Simple::Password
requires       'Digest::MD5'              => 0; # Authen::Simple::Password
requires       'Digest::SHA'              => 0; # Authen::Simple::Password
requires       'MIME::Base64'             => 0; # Authen::Simple::Password
requires       'Params::Validate'         => 0;
requires       'Test::More'               => 0;

tests 't/*.t t/*/*.t';

WriteAll;

