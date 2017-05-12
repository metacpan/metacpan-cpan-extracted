use inc::Module::Install;

all_from 'lib/App/Mver.pm';
readme_from 'lib/App/Mver.pm';

requires 'Pod::Parser';
requires 'version';
requires 'ExtUtils::MakeMaker';

recommends 'Module::CoreList';
recommends 'JSON::Any';
recommends 'LWP::Simple';
recommends 'CPAN::Changes';
install_script 'mver';

WriteAll;
