use inc::Module::Install;

name     'App-I18N';
all_from 'lib/App/I18N.pm';
author   q{Cornelius <cornelius.howl@gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'LWP::Simple';
requires 'Exporter::Lite';
requires 'File::Copy';
requires 'File::Find::Rule';
requires 'File::Path';
requires 'Locale::Maketext::Extract';
requires 'Locale::Maketext::Lexicon';
requires 'Getopt::Long';
requires 'Exporter';
requires 'JSON::XS';
requires 'Tatsumaki';
requires 'Plack';
requires 'File::ShareDir';
requires 'DBI';
requires 'DBIx::Class';
requires 'DBD::SQLite';
requires 'MIME::Types';
requires 'App::CLI';
requires 'Data::Dumper';
requires 'REST::Google::Translate';
requires 'Locale::Language';
requires 'YAML::XS';

install_script 'bin/po';

# author_tests('xt');

no_index( directory => qw< share > );
install_share;

auto_install;

WriteAll;
