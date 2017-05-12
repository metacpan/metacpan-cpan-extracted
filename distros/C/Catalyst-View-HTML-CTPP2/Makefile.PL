use inc::Module::Install;

if (-e 'MANIFEST.SKIP') {
    system('pod2text lib/Catalyst/View/HTML/CTPP2.pm > README');
}

name 'Catalyst-View-HTML-CTPP2';
all_from 'lib/Catalyst/View/HTML/CTPP2.pm';

build_requires 'Catalyst'    => '5.7';
build_requires 'HTML::CTPP2' => '2.005010';
build_requires 'MRO::Compat';
build_requires 'Path::Class';
build_requires 'File::Spec';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'ok';

test_requires 'Test::More';

WriteAll();
