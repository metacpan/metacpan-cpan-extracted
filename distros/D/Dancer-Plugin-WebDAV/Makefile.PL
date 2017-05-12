use inc::Module::Install;

name           'Dancer-Plugin-WebDAV';
all_from       'lib/Dancer/Plugin/WebDAV.pm';
author         'shelling <navyblueshellingford@gmail.com>';
repository     'https://github.com/shelling/dancer-plugin-webdav';
license        'MIT';
perl_version   '5.010';

requires       'Dancer';

test_requires  'Test::More';

tests          't/*.t';
author_tests   'xt';

auto_include;
WriteAll;
