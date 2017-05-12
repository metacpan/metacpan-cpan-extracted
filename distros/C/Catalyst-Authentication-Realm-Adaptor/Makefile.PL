use inc::Module::Install 0.91;

perl_version '5.8.1';

name 'Catalyst-Authentication-Realm-Adaptor';
all_from 'lib/Catalyst/Authentication/Realm/Adaptor.pm';


if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Authentication/Realm/Adaptor.pm > README');
}

requires (
            'Catalyst::Runtime' => 0,
	        'Catalyst::Plugin::Authentication' => 0.10003,
	        'Moose' => 0,
         );

test_requires ('Test::More' => 0.42);

WriteAll;
