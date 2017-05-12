use inc::Module::Install 1.05;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/I18N/Request.pm > README' );
}

perl_version '5.008';

name 'Catalyst-Plugin-I18N-Request';
all_from 'lib/Catalyst/Plugin/I18N/Request.pm';

requires 'Catalyst::Runtime' => '5.7000';
requires 'Catalyst::Plugin::I18N';
requires 'URI';
requires 'Scalar::Util';
requires 'MRO::Compat';

test_requires 'Test::More';

repository 'http://github.com/bricas/catalyst-plugin-i18n-request';

WriteAll;
