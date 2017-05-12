use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'Apache2-ASP';
perl_version '5.008001';
license 'perl';
all_from 'lib/Apache2/ASP.pm';

test_requires 'Test::More'          => '0.77';
test_requires 'Test::Memory::Cycle' => 0;
test_requires 'DBD::SQLite'         => 0;

requires    'Time::HiRes'             => 1.9715;          # For UploadHook frequency checks.
requires    'HTTP::Body'              => 1.04;            # HTTP POST parsing in test mode.
requires    'Data::Properties::YAML'  => 0.02;            # Properties files.
requires    'XML::Simple'             => 2.18;            # Configuration file parsing.
#requires    'CGI::Apache2::Wrapper'   => 0.215;           # HTTP POST parsing.
requires    'Cwd'                     => 3.2701;          # Configuration file discovery.
requires    'Digest::MD5'             => 2.36;            # Session and Application state.
requires    'DBI'                     => 1.607;           # Session and Application state.
requires    'DBD::SQLite'             => 1.14;            # For testing.
requires    'Storable'                => 2.18;            # Session and Application state.
requires    'HTTP::Date'              => 5.810;           # For Session timeouts.
requires    'MIME::Types'             => 1.24;            # For MediaManager.
requires    'Mail::Sendmail'          => 0.79;            # For sending email.
requires    'HTML::Form'              => 5.817;           # For Apache2::ASP::Test::*
requires    'HTTP::Request::AsCGI'    => 0.5;             # For Apache2::ASP::Test::*
requires    'CGI::Simple'             => 1.106;           # For Apache2::ASP::Test::*
requires    'CGI'                     => 3.43;            # For...cgi stuff...
requires    'Ima::DBI'                => 0.35;            # For sessions & applications.
requires    'XML::Parser'             => 2.36;            # For XML::Simple.
requires    'IO::File'                => 1.14;            # For MediaManager
requires    'Encode'                  => 2.23;            # For Server.URLDecode

install_script 'sbin/runasp';
install_script 'sbin/asphelper';

tests_recursive();
WriteAll();

