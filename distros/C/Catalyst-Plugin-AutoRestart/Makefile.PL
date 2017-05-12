use inc::Module::Install '0.68';

name 'Catalyst-Plugin-AutoRestart';
all_from 'lib/Catalyst/Plugin/AutoRestart.pm';

# needs cat version with Catalyst::ClassData
requires 'Catalyst' => '5.90005';
requires 'MRO::Compat' => '0.07';
requires 'Text::SimpleTable' => '0.03';
requires 'Proc::ProcessTable' => '0.41';

# generate README file
if ($Module::Install::AUTHOR) {
  system('pod2text lib/Catalyst/Plugin/AutoRestart.pm > README');
}

tests_recursive();
auto_install;
WriteAll;

