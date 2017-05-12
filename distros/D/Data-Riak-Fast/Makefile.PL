use inc::Module::Install;
name 'Data-Riak-Fast';
all_from 'lib/Data/Riak/Fast.pm';

requires 'Digest::MD5';
requires 'Furl';
requires 'Net::DNS::Lite';
requires 'Cache::LRU';
requires 'HTTP::Headers::ActionPack';
requires 'HTTP::Message';
requires 'JSON::XS';
requires 'Mouse';
requires 'Sub::Exporter';
requires 'Try::Tiny';
requires 'URI';
requires 'URL::Encode';

tests_recursive;
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Test::Memory::Cycle';
auto_set_repository;
auto_include;
WriteAll;
