use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Which qw(which);

# Use a private registry for this class

# Check for required system dependencies
print "Checking system dependencies...\n";

# Check if 'mysqld' is installed
my $mysqld_check = which('mysqld') || which('mariadb');

if ( !$mysqld_check ) {
    print STDERR "'mysqld' is not found on the system. Please ensure MySQL is installed.\n";
}

my $TEST_REQUIRES = {
    'Try::Tiny'                 => '0.32',
    'DBI'                       => '1.656',
    'Test2::V0'                 => '0.000145',
    'DBD::SQLite'               => '1.74',
    'Exporter::Shiny'           => '1.006003',
    'Rose::DB'                  => '0.788',
    'Rose::DB::Object'          => '0.822',
    'Rose::DB::Object::Manager' => '0.813',
    'Rose::DB::Object::Loader'  => '0.799',
    'Sub::Override'             => '0.12',
    'autodie'                   => '2.37',
};

print "MySQL detected. Adding MySQL-related test dependencies...\n";
$TEST_REQUIRES->{'DBD::mysql'}      = '5.012';
$TEST_REQUIRES->{'Rose::DB::MySQL'} = '0.774';
$TEST_REQUIRES->{'Test::mysqld'}    = '1.0030';

# Write the Makefile
WriteMakefile(
    NAME         => 'DBD::Mock::Session::GenerateFixtures',
    ABSTRACT     => 'This distribution generates fixtures for DBD-Mock-Session module',
    VERSION_FROM => 'lib/DBD/Mock/Session/GenerateFixtures.pm',                           # finds $VERSION
    LICENSE      => 'perl',
    AUTHOR       => 'Dragos Trif <your.email@example.com>',
    META_MERGE   => {
        resources => {
            repository => 'https://github.com/DragosTrif/DBD-Fixtures',
        },
    },
    PREREQ_PM => {
        'Carp'             => '1.50',
        'DBD::Mock'        => '1.60',
        'Sub::Override'    => '0.12',
        'English'          => '1.11',
        'File::Path'       => '2.18',
        'Cpanel::JSON::XS' => '4.80',
        'File::Slurper'    => '0.014',
        'File::Spec'       => '3.75',
        'Readonly'         => '2.05',
        'Data::Walk'       => '2.01',
        'Try::Tiny'        => '0.32',
        'File::Which'      => '1.27',
        'Sub::Exporter'    => '0.992',

    },
    TEST_REQUIRES    => $TEST_REQUIRES,
    MIN_PERL_VERSION => '5.14.4',
);

