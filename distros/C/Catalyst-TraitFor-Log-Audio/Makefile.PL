use inc::Module::Install 0.91;
  
# Define metadata
name           'Catalyst-TraitFor-Log-Audio';
all_from       'lib/Catalyst/TraitFor/Log/Audio.pm';
  
# Specific dependencies
requires       'Catalyst::Runtime' => '5.80';
requires       'Moose' => '0.80';
test_requires  'Test::More'  => '0.42';

WriteAll;
