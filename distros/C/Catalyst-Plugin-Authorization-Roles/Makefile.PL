use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/Authorization/Roles.pm > README' );
}

perl_version '5.008';

name 'Catalyst-Plugin-Authorization-Roles';
all_from 'lib/Catalyst/Plugin/Authorization/Roles.pm';

requires 'Catalyst::Runtime'                => '5.7';
requires 'Catalyst::Plugin::Authentication' => '0.10003';
requires 'Set::Object'                      => '1.14';
requires 'UNIVERSAL::isa'                   => '0.05';

test_requires 'Test::More';
test_requires 'Test::Exception';

repository 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Authorization-Roles/';

WriteAll;
