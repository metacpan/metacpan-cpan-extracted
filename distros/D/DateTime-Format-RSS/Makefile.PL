use strict;
use inc::Module::Install;

name('DateTime-Format-RSS');
all_from("lib/DateTime/Format/RSS.pm");

requires 'DateTime::Format::Mail';
requires 'DateTime::Format::ISO8601';
requires 'DateTime::Format::DateParse';
requires 'Class::Accessor::Fast';

test_requires 'Test::More';

auto_include;
WriteAll;

