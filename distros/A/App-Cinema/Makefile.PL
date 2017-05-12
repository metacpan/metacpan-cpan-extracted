#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'App-Cinema';
all_from 'lib/App/Cinema.pm';

requires 'Catalyst' => '5.7002';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Model::DBIC::Schema';
requires 'DBIx::Class';
requires 'DBIx::Class::Schema';
requires 'Catalyst::View::TT';
requires 'Catalyst::Controller::FormBuilder';
requires 'Catalyst::Controller';
requires 'DBD::SQLite';
requires 'YAML::XS';
requires 'YAML';
requires 'HTTP::Date';
requires 'Captcha::reCAPTCHA';
requires 'Mail::Mailer';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
