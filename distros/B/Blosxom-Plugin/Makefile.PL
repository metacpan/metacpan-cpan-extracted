use inc::Module::Install;

all_from 'lib/Blosxom/Plugin.pm';

repository 'https://github.com/anazawa/p5-Blosxom-Plugin';

requires 'parent';
requires 'CGI' => '3.51';
requires 'Data::Section::Simple';
requires 'File::Spec::Unix';
requires 'IO::File';

test_requires 'Test::More' => '0.98';
test_requires 'Test::Pod';
test_requires 'Test::Exception';

no_index package => 'Fh';

WriteAll;
