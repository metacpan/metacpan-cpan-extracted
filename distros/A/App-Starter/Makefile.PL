use inc::Module::Install;
name 'App-Starter';
all_from 'lib/App/Starter.pm';
requires 'Test::More'      => 0;
requires 'YAML::Syck'      => 0;
requires 'Template'        => 0;
requires 'IO::All'         => 0;
requires 'Class::Accessor' => 0;
requires 'FindBin::libs'   => 0;
requires 'Getopt::Long'    => 0;
requires 'Test::Spelling'  => 0;

install_script glob('bin/*.pl');
license 'perl';
auto_install;
WriteAll;
