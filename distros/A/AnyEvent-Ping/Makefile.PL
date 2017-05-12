use inc::Module::Install;

name 'AnyEvent-Ping';
all_from 'lib/AnyEvent/Ping.pm';
install_script 'ping.pl';

requires 'AnyEvent';
requires 'Carp';
requires 'List::Util';
requires 'Test::More' => '0.88';

tests 't/*.t';

resources
  bugtracker => 'https://github.com/und3f/anyevent-ping/issues',
  repository => 'http://github.com/und3f/anyevent-ping';

WriteAll;
