use strict;
use inc::Module::Install;

print <<EOM;


***** WARNING ******
This module has been DEPRECATED.

Please consider moving to Catalyst::Controller::HTML::FormFu instead
********************


EOM

name 'Catalyst-Model-HTML-FormFu';
all_from 'lib/Catalyst/Model/HTML/FormFu.pm';

requires 'Best';
requires 'Catalyst';
requires 'Config::Any';
requires 'Data::Dumper';
requires 'Data::Visitor::Callback';
requires 'Digest::MD5';
requires 'HTML::FormFu', '0.02000';

build_requires 'Test::More';
build_requires 'Catalyst::Test';

auto_install;
WriteAll(meta => 1);

