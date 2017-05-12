use inc::Module::Install;
name 'AnyEvent-MPRPC';
all_from 'lib/AnyEvent/MPRPC.pm';

requires 'AnyEvent'          => 5.261;
requires 'Data::MessagePack' => 0.34;
requires 'Data::MessagePack::Stream' => '0.05';
requires 'Any::Moose'        => 0.13;
requires 'AnyEvent::MessagePack' => 0.19;

tests 't/*.t';
test_requires 'Test::More'       => 0.94;
test_requires 'Test::TCP'        => 0.11;
author_tests 'xt';

test_requires 'Test::TCP' => 0.11;
test_requires 'Test::More' => 0.98;
WriteAll;

