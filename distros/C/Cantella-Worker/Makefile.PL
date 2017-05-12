use inc::Module::Install;

name 'Cantella-Worker';
all_from 'lib/Cantella/Worker.pm';

requires 'POE' => '1.000';
requires 'Moose' => '0.94';
requires 'Data::GUID' => '0.044';
requires 'MooseX::Types' => '0.15';
requires 'Log::Dispatch' => '2.26';
requires 'POE::Wheel::Run' => '1.000';
requires 'MooseX::Types::Log::Dispatch' => '0.002000';
requires 'MooseX::Types::Common' => '0.001002';

#tests
test_requires 'Try::Tiny';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Log::Dispatch::Array';

resources 'IRC' => 'irc://irc.perl.org/#poe';
resources 'license' => 'http://dev.perl.org/licenses/';
resources 'repository' => 'git://github.com/groditi/Cantella-Worker.git';

WriteAll;
