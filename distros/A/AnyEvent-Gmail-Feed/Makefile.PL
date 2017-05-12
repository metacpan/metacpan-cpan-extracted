use inc::Module::Install;
name 'AnyEvent-Gmail-Feed';
all_from 'lib/AnyEvent/Gmail/Feed.pm';

requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'MIME::Base64';
requires 'Net::SSLeay';
requires 'XML::Atom::Feed';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
WriteAll;
