use inc::Module::Install;

name 'Catalyst-Authentication-Store-Tangram';
all_from 'lib/Catalyst/Authentication/Store/Tangram.pm';

license 'perl';

requires 'Catalyst::Plugin::Authentication' => '0.10003';
requires 'Catalyst::Runtime' => '5.70';
requires 'Tangram' => '2.09';
requires 'Class::Accessor::Fast';

build_requires 'MRO::Compat';
build_requires 'File::Temp';
build_requires 'DBI';
build_requires 'DBD::SQLite';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';

resources repository => 'https://badger.state51.co.uk/svn/cpan/Catalyst-Authentication-Store-Tangram';

WriteAll();
