use inc::Module::Install 0.67;
perl_version '5.008001';
  
name        'Class-Accessor-Fast-Contained';
all_from    'lib/Class/Accessor/Fast/Contained.pm';

requires    'base' => 0;
requires    'Class::Accessor' => 0;

test_requires  'Test::More' => 0;
test_requires  'Test::Pod' => 0;
test_requires  'Test::Pod::Coverage' => 0;

WriteAll;

