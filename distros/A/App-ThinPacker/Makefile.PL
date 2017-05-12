use inc::Module::Install;

all_from 'lib/App/ThinPacker.pm';

requires 'PPI';
requires 'Pod::Usage';
requires 'Pod::Find';

install_script 'script/thinpack';

WriteAll;
