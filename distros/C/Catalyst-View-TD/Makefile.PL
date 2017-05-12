use inc::Module::Install 0.87;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/View/TD.pm > README' );
}

perl_version '5.008001';

name 'Catalyst-View-TD';
all_from 'lib/Catalyst/View/TD.pm';

requires 'Catalyst'          => '5.7';
requires 'Template::Declare' => '0.42';
requires 'File::Find'        => 0;
requires 'Class::Accessor'   => 0;
requires 'MRO::Compat'       => 0;

test_requires 'Test::More';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-View-TD/trunk';

WriteAll;
