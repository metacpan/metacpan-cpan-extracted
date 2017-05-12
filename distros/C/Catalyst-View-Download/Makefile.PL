use inc::Module::Install;

name 'Catalyst-View-Download';
all_from 'lib/Catalyst/View/Download.pm';

build_requires 'Catalyst::Runtime';
build_requires 'Catalyst::View';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';
build_requires 'Text::CSV';
build_requires 'XML::Simple';
build_requires 'FindBin';
build_requires 'ok';

WriteAll();
