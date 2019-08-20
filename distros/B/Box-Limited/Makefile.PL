use inc::Module::Install;

all_from 'lib/Box/Limited.pm';
repository 'https://github.com/ichesnokov/p5-box-limited';

requires 'Moo'               => 0;
requires 'Type::Tiny'        => 0;
requires 'Test::Differences' => 0;
requires 'Test::Fatal'       => 0;
requires 'Test::Roo'         => 0;

WriteAll(meta => 1);
