use inc::Module::Install 0.95;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/ConfigLoader.pm > README' );
}

perl_version '5.008';

name 'Catalyst-Plugin-ConfigLoader';
all_from 'lib/Catalyst/Plugin/ConfigLoader.pm';

requires 'Catalyst::Runtime' => '5.7008';    # needed for env_value()
requires 'Data::Visitor'     => '0.24';
requires 'Config::Any'       => '0.20';
requires 'MRO::Compat'       => '0.09';

test_requires 'Test::More';
test_requires 'Path::Class';

resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-Plugin-ConfigLoader.git';

WriteAll;
