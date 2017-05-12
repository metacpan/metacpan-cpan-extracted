use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'ASP4';
perl_version '5.008005';
license 'perl';
all_from 'lib/ASP4.pm';

test_requires 'Test::More'          => 0;
test_requires 'Test::Memory::Cycle' => 0;
#test_requires 'DBD::SQLite'         => 0;
test_requires 'Time::HiRes'         => 0;
test_requires 'HTML::Form'          => 0;

requires    'common::sense'           => 0;
requires    'Data::Properties::YAML'  => 0;
requires    'Data::Properties::JSON'  => 0;
requires    'Cwd'                     => 0;
requires    'Digest::MD5'             => 0;       # Session state.
requires    'DBI'                     => 0;       # Session state.
requires    'Ima::DBI::Contextual'    => 0;       # Session state.
requires    'Storable'                => 0;       # Session state.
requires    'HTTP::Date'              => 0;       # For Session timeouts.
requires    'Time::HiRes'             => 0;       # For Session ids.
requires    'Mail::Sendmail'          => 0;       # For sending email.
requires    'CGI'                     => 3.43;    # For...cgi stuff...
requires    'HTTP::Body'              => 0;
requires    'JSON::XS'                => 0;       # For Configs
requires    'Term::ReadKey'           => 0;       # For asphelper script.

recommends  'ASP4x::Router'           => 0.020;   # For routing.

install_script 'sbin/asp4';
install_script 'sbin/asp4-prep';
install_script 'sbin/asp4-deploy';
install_script 'sbin/asphelper';
resources(
  'repository'  => 'https://github.com/jdrago999/ASP4'
);

tests_recursive();
WriteAll();

