use inc::Module::Install 0.87;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/I18N.pm > README' );
}

perl_version '5.008';

name 'Catalyst-Plugin-I18N';
all_from 'lib/Catalyst/Plugin/I18N.pm';

requires 'Catalyst::Runtime';
requires 'Locale::Maketext::Simple' => "0.19";
requires 'I18N::LangTags' => '0.35';
requires 'Locale::Maketext::Lexicon';
requires 'MRO::Compat' => '0.10';

test_requires 'Test::More';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-I18N/trunk/';

WriteAll;
