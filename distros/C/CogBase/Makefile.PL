use inc::Module::Install;

name            'CogBase';
all_from        'lib/CogBase.pm';

requires 'IO::All';
requires 'XXX';
requires 'YAML::Syck';
requires 'Convert::Base32';
requires 'Data::UUID';
requires 'Digest::MD5';
requires 'Class::Field';

use_test_base;

clean_files 't/cogbase-test-db';

WriteAll;
