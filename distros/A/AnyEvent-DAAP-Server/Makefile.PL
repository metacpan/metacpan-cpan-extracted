use inc::Module::Install;

name 'AnyEvent-DAAP-Server';
all_from 'lib/AnyEvent/DAAP/Server.pm';

requires 'Any::Moose';
requires 'AnyEvent';
requires 'AnyEvent::Socket';
requires 'AnyEvent::Handle';
requires 'Net::Rendezvous::Publish';
requires 'Net::DAAP::DMAP';
requires 'Router::Simple';
requires 'HTTP::Request';
requires 'HTTP::Response';
requires 'URI';
requires 'URI::QueryParam';

requires 'MP3::Info';
requires 'File::Basename';
requires 'File::Find::Rule';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;

WriteAll;
