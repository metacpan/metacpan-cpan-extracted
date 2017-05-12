use inc::Module::Install;

name     'DateTime-Format-Sybase';
all_from 'lib/DateTime/Format/Sybase.pm';
author   'Rafael Kitover <rkitover@cpan.org>';
license  'perl';

test_requires 'Test::More';

requires 'DateTime';
requires 'DateTime::Format::Strptime';

auto_provides;
auto_install;

resources repository =>
    'git://github.com/rkitover/datetime-format-sybase.git';

WriteAll;
