use inc::Module::Install;
name 'AnyEvent-Groonga';
all_from 'lib/AnyEvent/Groonga.pm';

requires 'AnyEvent';
requires 'AnyEvent::Util';
requires 'AnyEvent::HTTP';
requires 'File::Which';
requires 'List::MoreUtils';
requires 'URI';
requires 'URI::Escape';
requires 'JSON';
requires 'Try::Tiny';
requires 'Encode';
requires 'Class::Accessor::Fast';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'FindBin';
test_requires 'File::Spec';

auto_include;
WriteAll;
