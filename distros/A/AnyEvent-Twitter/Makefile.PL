use inc::Module::Install;
name 'AnyEvent-Twitter';
all_from 'lib/AnyEvent/Twitter.pm';

requires 'JSON'           => 2.53;
requires 'Net::OAuth'     => 0.27;
requires 'Digest::SHA'    => 5.62;
requires 'AnyEvent'       => 5.34;
requires 'AnyEvent::HTTP' => 2.12;
requires 'URI'            => 1.58;
requires 'URI::Escape'    => 3.30;
requires 'Net::SSLeay'    => 1.35;
requires 'Time::Piece'    => 1.20;
requires 'HTTP::Request::Common'   => 6.04;
requires 'Data::Recursive::Encode' => 0.04;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => 0.98;
auto_set_repository;
auto_include;
WriteAll;
