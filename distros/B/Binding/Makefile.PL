use inc::Module::Install;

all_from 'lib/Binding.pm';

build_requires  'Test::More'        => '0.42';

requires
    'UNIVERSAL::isa'   => 0,
    'PadWalker'        => 1.7,
    'Devel::Caller'    => 2.03,
    'Data::Dump'       => 1.14;

tests 't/*.t';
author_tests 'xt/*.t';

WriteAll;


