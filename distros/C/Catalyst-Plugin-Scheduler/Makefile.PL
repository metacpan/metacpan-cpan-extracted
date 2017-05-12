use inc::Module::Install 0.91;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/Scheduler.pm > README' );
}

perl_version '5.008';

name 'Catalyst-Plugin-Scheduler';
all_from 'lib/Catalyst/Plugin/Scheduler.pm';

requires 'Catalyst::Runtime' => '5.61';
requires 'DateTime::Event::Cron';
requires 'Set::Scalar';
requires 'Storable';
requires 'YAML';
requires 'MRO::Compat';

test_requires 'Test::More';

WriteAll;
