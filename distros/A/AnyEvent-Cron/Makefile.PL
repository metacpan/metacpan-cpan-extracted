use inc::Module::Install;
name     'AnyEvent-Cron';
all_from 'lib/AnyEvent/Cron.pm';
author   q{Cornelius <cornelius.howl_at_gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'DateTime';
requires 'AnyEvent';
requires 'Moose';
requires 'Try::Tiny';
requires 'DateTime::Event::Cron';
auto_install;
WriteAll;
