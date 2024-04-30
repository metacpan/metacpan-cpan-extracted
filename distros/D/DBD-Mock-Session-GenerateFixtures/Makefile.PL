use inc::Module::Install;

name 'DBD-Mock-Session-GenerateFixtures';
all_from 'lib/DBD/Mock/Session/GenerateFixtures.pm';
version_from 'lib/DBD/Mock/Session/GenerateFixtures.pm';

requires 'Carp'             => '1.52';
requires 'DBD::Mock'        => '1.59';
requires 'Sub::Override'    => '0.10';
requires 'English'          => '1.11';
requires 'File::Path'       => '2.18';
requires 'Cpanel::JSON::XS' => '4.37';
requires 'File::Slurper'    => '0.014';
requires 'File::Spec'       => '3.84';
requires 'Readonly'         => '2.05';
requires 'Data::Walk'       => '2.01';

test_requires 'DBI'         => '1.643';
test_requires 'Test2::V0'   => '0.000145';
test_requires 'DBD::SQLite' => '1.74';

WriteAll;
