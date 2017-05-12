#!perl

use Test::Simple tests => 16;

use File::Spec;
use Config::IniFiles;

use DBIx::PasswordIniFile;

$ini_file = File::Spec->catfile('.','t','new.ini');
$config = new Config::IniFiles;

%h = (
    driver => 'DRIVER',
    database => 'DATABASE',
    host => 'HOST',
    port => 'PORT',
    username => 'USERNAME',
    password => 'PASSWORD',

    # Not managed by DBIx::PasswordIniFile
    dsn => 'DSN',
    table => 'TABLE'
);

%hattr = (
    attribute1 => 'value1',
    attribute2 => 'value2',
    attribute3 => 'value3'
);

$section_names = ['connect', 'connection', 'database', 'db', 'dsn', 'virtual user'];

# With $section argument

&createIniFile('any_section');
$virtual_user = new DBIx::PasswordIniFile(-file => $ini_file, -section => 'any_section');

ok( ref($virtual_user) eq 'DBIx::PasswordIniFile', 
    'new. section=any_section');

ok(    exists $virtual_user->{config_} 
    && ref($virtual_user->{config_})  eq 'Config::IniFiles'
 
    && exists $virtual_user->{section_}  
    && $virtual_user->{section_} eq 'any_section'
 
    && exists $virtual_user->{key_}  
 
    && exists $virtual_user->{cipher_}  
    && $virtual_user->{cipher_} eq 'Blowfish'
 
    && exists $virtual_user->{dbh_}

    ,'object. section=any_section');

# Default section doesn't exists

$virtual_user = new DBIx::PasswordIniFile(-file => $ini_file);
ok( !defined($virtual_user), 'default section doesn\'t exist');

# Default section exists

foreach my $section ( @$section_names )
{
    &createIniFile($section);
    $virtual_user = new DBIx::PasswordIniFile( -file => $ini_file);

    ok( ref($virtual_user) eq 'DBIx::PasswordIniFile', 
        "new. section=$section");

    ok(    exists $virtual_user->{config_}  
        && ref($virtual_user->{config_}) eq 'Config::IniFiles'

        && exists $virtual_user->{section_}  
        && $virtual_user->{section_} eq $section
 
        && exists $virtual_user->{key_}  
 
        && exists $virtual_user->{cipher_}  
        && $virtual_user->{cipher_} eq 'Blowfish'

        && exists $virtual_user->{dbh_},

        "object. section=$section");
}

# File does't exists
$virtual_user = new DBIx::PasswordIniFile( -file => 'file_does_not_exists.ini',
                                           -section => 'any_section');
ok( !defined($virtual_user), 'File does not exists' );


#-----------------------------------------------------------------------------
# Functions

sub createIniFile
{
    my $section_name = shift;

    $config->Delete();

    $config->AddSection($section_name);
    $config->AddSection("${section_name}_attributes");

    my($par,$val);
    while( ($par,$val) = each %h )
    {
        $config->newval($section_name,$par,$val);
    }

    while( ($par,$val) = each %hattr )
    {
        $config->newval("${section_name}_attributes",$par,$val);
    }
    
    $config->SetFileName( $ini_file );
    $config->RewriteConfig();
}

1;
