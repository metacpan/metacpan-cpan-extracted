use inc::Module::Install 0.87;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/View/Markdown.pm > README' );
}

perl_version '5.008001';

name 'Catalyst-View-Markdown';
all_from 'lib/Catalyst/View/Markdown.pm';

requires 'Catalyst'        => '5.7';
requires 'Text::Markdown'  => 0;
requires 'Class::Accessor' => 0;
requires 'Path::Class'     => 0;
requires 'MRO::Compat'     => 0;

test_requires 'Test::More';

auto_install;
resources repository => 'https://github.com/bossolutions/Catalyst-View-Markdown.git';

WriteAll;
