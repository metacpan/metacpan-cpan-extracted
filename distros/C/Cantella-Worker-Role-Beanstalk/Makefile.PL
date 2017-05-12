use inc::Module::Install;

name 'Cantella-Worker-Role-Beanstalk';
all_from 'lib/Cantella/Worker/Role/Beanstalk.pm';

requires 'List::Util';
requires 'Moose' => '0.94';
requires 'Log::Dispatch' => '2.26';
requires 'Cantella::Worker' => '0.001000';
requires 'Beanstalk::Client' => '1.06';
requires 'MooseX::Types::Common::Numeric' => '0.001000';

#tests
test_requires 'Test::Most';
test_requires 'Log::Dispatch::Array';

resources 'IRC' => 'irc://irc.perl.org/#poe';
resources 'license' => 'http://dev.perl.org/licenses/';
resources 'repository' => 'git://github.com/groditi/Cantella-Worker-Role-Beanstalk.git';

WriteAll;
