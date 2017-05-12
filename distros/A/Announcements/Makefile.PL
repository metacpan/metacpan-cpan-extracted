use inc::Module::Install;

name     'Announcements';
all_from 'lib/Announcements.pm';
githubmeta;

requires 'Moose';
test_requires 'Test::More' => '0.88';

WriteAll;

