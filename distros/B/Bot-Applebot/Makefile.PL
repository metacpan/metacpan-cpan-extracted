use inc::Module::Install;

name     'Bot-Applebot';
all_from 'lib/Bot/Applebot.pm';
githubmeta;

requires 'Moose';
requires 'MooseX::AttributeHelpers';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'IO::All';
requires 'String::IRC';
requires 'Lingua::EN::Inflect';
requires 'Roman';
requires 'File::ShareDir';
requires 'YAML';

recommends 'Net::Twitter';

install_script 'bin/applebot';
install_share;

WriteAll;

