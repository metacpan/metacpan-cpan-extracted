use inc::Module::Install 0.65;

name 'Catalyst-Plugin-Authentication-Store-DBIC';
all_from 'lib/Catalyst/Plugin/Authentication/Store/DBIC.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::Plugin::Authentication' => '0.06';
requires 'Set::Object' => '1.14';
requires 'Class::Accessor::Fast';
requires 'DBIx::Class';
requires 'Catalyst::Model::DBIC::Schema';

feature 'Roles support',
    -default                                 => 1,
    'Catalyst::Plugin::Authorization::Roles' => '0.03';

feature 'Cookie support',
    -default                                   => 1,
    'Catalyst::Plugin::Session::State::Cookie' => '0.02';

feature 'Class::DBI support',
    -default     => 0,
    'Class::DBI' => 0;

feature 'Test::WWW::Mechanize::Catalyst for testing',
    -default                         => 0,
    'Test::WWW::Mechanize::Catalyst' => 0;

auto_install;
WriteAll;
