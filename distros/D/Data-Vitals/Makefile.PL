use inc::Module::Install 0.75;

all_from      'lib/Data/Vitals.pm';
test_requires 'Test::More'     => '0.47';
test_requires 'Test::ClassAPI' => '1.02';
test_requires 'File::Spec'     => '0.82';

WriteAll;
