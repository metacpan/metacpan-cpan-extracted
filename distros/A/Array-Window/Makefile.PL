use inc::Module::Install 0.75;

all_from      'lib/Array/Window.pm';
requires      'Params::Util' => '0.12';
test_requires 'Test::More'   => '0.47';

WriteAll;
