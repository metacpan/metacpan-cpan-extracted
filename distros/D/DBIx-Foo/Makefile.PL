
use inc::Module::Install;
  
# Define metadata
name          'DBIx-Foo';

author        'Mike Tonks <miket@cpan.org>';
version_from  'lib/DBIx/Foo.pm';
license       'perl', 'gpl';
 
# Specific dependencies
requires 'DBI'  => 0;
requires 'Exporter'  => 0;
requires 'Log::Any'  => 0;
requires 'Tie::IxHash' => 0;

# Recommended modules
#recommends 'DBD::SQLite' => 0;

# Modules required for testing
test_requires 'Test::More' => 0;
test_requires 'DBD::SQLite' => 0;

#manifest_skip;

WriteAll;
