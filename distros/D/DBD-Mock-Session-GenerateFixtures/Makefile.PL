# use ExtUtils::MakeMaker;

# # Check for required system dependencies
# print "Checking system dependencies...\n";

# # Check if 'mysqld' is installed
# my $mysqld_check       = system("which mysqld > /dev/null 2>&1");
# my $mysql_config_check = system("which mysql_config > /dev/null 2>&1");

# if ($mysqld_check != 0) {
#     print STDERR "'mysqld' is not found on the system. Please ensure MySQL is installed.\n";
# }

# if ($mysql_config_check != 0) {
#     print STDERR "'mysql_config' is not found on the system. Please ensure MySQL development headers are installed.\n";
# }

# # Write the Makefile
# WriteMakefile(
#     NAME             => 'DBD::Mock::Session::GenerateFixtures',
#     ABSTRACT         => 'This distribution generates fixtures for DBD-Mock-Session module',
#     VERSION_FROM     => 'lib/DBD/Mock/Session/GenerateFixtures.pm', # finds $VERSION
#     LICENSE          => 'perl',
#     AUTHOR           => 'Dragos Trif <your.email@example.com>',
#     META_MERGE       => {
#         resources => {
#             repository => 'https://github.com/DragosTrif/DBD-Fixtures',
#         },
#     },
#     PREREQ_PM        => {
#         'Carp'             => '1.50',
#         'DBD::Mock'        => '1.59',
#         'Sub::Override'    => '0.12',
#         'English'          => '1.11',
#         'File::Path'       => '2.18',
#         'Cpanel::JSON::XS' => '4.37',
#         'File::Slurper'    => '0.014',
#         'File::Spec'       => '3.75',
#         'Readonly'         => '2.05',
#         'Data::Walk'       => '2.01',
#         'Try::Tiny'        => '0.32',
#     },
#     TEST_REQUIRES    => {
#         'Try::Tiny'                  => '0.32',
#         'DBI'                        => '1.643',
#         'Test2::V0'                  => '0.000145',
#         'DBD::SQLite'                => '1.74',
#         'Exporter::NoWork'           => '0.03',
#         'Rose::DB'                   => '0.786',
#         'Rose::DB::Object'           => '0.822',
#         'Rose::DB::Object::Manager'  => '0.813',
#         'Rose::DB::Object::Loader'   => '0.799',
#         'Sub::Override'              => '0.12',
#         'autodie'                    => '2.37',
#     },
#     MIN_PERL_VERSION => '5.14.4',
# );

# # Add optional dependencies if MySQL is available
# if ($mysqld_check == 0 && $mysql_config_check == 0) {
#     print "MySQL detected. Adding MySQL-related test dependencies...\n";
#     WriteMakefile(
#         TEST_REQUIRES => {
#             'DBD::mysql'        => '5.012',
#             'Rose::DB::MySQL'   => '0.774',
#             'Test::mysqld'      => '1.0030',
#         },
#     );
# }
use inc::Module::Install;

name 'DBD-Mock-Session-GenerateFixtures';
abstract 'This distribution generates fixtures for DBD-Mock-Session module';
repository 'https://github.com/DragosTrif/DBD-Fixtures';

all_from 'lib/DBD/Mock/Session/GenerateFixtures.pm';
version_from 'lib/DBD/Mock/Session/GenerateFixtures.pm';


# Check for required system dependencies
print "Checking system dependencies...\n";

# Check if 'mysqld' is installed
my $mysqld_check       = system("which mysqld > /dev/null 2>&1");
my $mysql_config_check = system("which mysql_config > /dev/null 2>&1");

perl_version => '5.14.4';

requires 'Carp'                           => '1.50';
requires 'DBD::Mock'                      => '1.59';
requires 'Sub::Override'                  => '0.12';
requires 'English'                        => '1.11';
requires 'File::Path'                     => '2.18';
requires 'Cpanel::JSON::XS'               => '4.37';
requires 'File::Slurper'                  => '0.014';
requires 'File::Spec'                     => '3.75';
requires 'Readonly'                       => '2.05';
requires 'Data::Walk'                     => '2.01';
test_requires 'Try::Tiny'                 => '0.32';

test_requires 'DBI'                       => '1.643';
test_requires 'Test2::V0'                 => '0.000145';
test_requires 'DBD::SQLite'               => '1.74';
test_requires 'Exporter::NoWork'          => '0.03';
test_requires 'Rose::DB'                  => '0.786';
test_requires 'Rose::DB::Object'          => '0.822';
test_requires 'Rose::DB::Object::Manager' => '0.813';
test_requires 'Rose::DB::Object::Loader'  => '0.799';
test_requires 'Sub::Override'             => '0.12';
test_requires 'Try::Tiny'                 => '0.32';
test_requires 'autodie'                   => '2.37';


if ($mysqld_check == 0 && $mysql_config_check == 0) {
    test_requires 'DBD::mysql'                => '5.012';
    test_requires 'Rose::DB::MySQL'           => '0.774';
    test_requires 'Test::mysqld'              => '1.0030';
}

WriteAll;
