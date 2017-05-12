use inc::Module::Install;

license     'perl';
name        'Catalyst-Plugin-Images';
all_from    'lib/Catalyst/Plugin/Images.pm';
perl_version '5.8.1';
requires 'Catalyst'       => '5.70';
requires 'Image::Size';
requires 'Path::Class';
requires 'HTML::Entities';
requires 'MRO::Compat';
test_requires 'Test::WWW::Mechanize::Catalyst';

WriteAll;

