#!perl -w

use Test::Simple tests => 3;

use DBIx::PasswordIniFile;
use Config::IniFiles;
use File::Spec;

$section = 'connection';
$dsn  = 'dbi:driver:anything';
$user = 'USER';
$pass = '----------';

# Files
$encpassw_pl = File::Spec->catfile('.', 'blib', 'script', 'encpassw.pl');
$password_ini = File::Spec->catfile('.', 't', 'password.ini');

# Make .ini file
$cfg = new Config::IniFiles;
$cfg->AddSection( 'connection ' );
$cfg->newval($section, 'dsn',  $dsn);
$cfg->newval($section, 'user', $user);
$cfg->newval($section, 'pass', $pass);
$cfg->SetFileName( $password_ini );
$cfg->RewriteConfig();

#-----------------------------------
# Test encpassw.pl with default key
#-----------------------------------

$pass = 'this is a clear password';
$cfg->setval($section, 'pass', $pass );
$cfg->RewriteConfig();

$resp = qx/perl -Mblib $encpassw_pl --inifile $password_ini --section $section/;

$conn = new DBIx::PasswordIniFile( -file => $password_ini ); 
$connect_params = $conn->getDBIConnectParams;

ok( $dsn  eq $connect_params->[0] &&
    $user eq $connect_params->[1] &&
    $pass eq $connect_params->[2],    'encpassw.pl without key' );


#-----------------------------------
# Test encpassw.pl with key
#-----------------------------------

$pass = 'this is a clear password';
$key  = 'this_is_a_key';

$cfg->setval($section, 'pass', $pass );
$cfg->RewriteConfig();

$resp = qx/perl -Mblib $encpassw_pl --inifile $password_ini --section $section --key $key/;

$conn = new DBIx::PasswordIniFile( -file => $password_ini, -key => $key ); 
$connect_params = $conn->getDBIConnectParams;

ok( $dsn  eq $connect_params->[0] &&
    $user eq $connect_params->[1] &&
    $pass eq $connect_params->[2],    'encpassw.pl with key' );

#-----------------------------------
# Test encpassw.pl with key and attrs
#-----------------------------------

$pass = 'this is a clear password';
$key  = 'this_is_a_key';

$cfg->setval($section, 'pass', $pass );
$cfg->newval($section, 'attr1', 'ATTR1' );
$cfg->newval($section, 'attr2', 'ATTR2' );
$cfg->RewriteConfig();

$resp = qx/perl -Mblib $encpassw_pl --inifile $password_ini --section $section --key $key/;

$conn = new DBIx::PasswordIniFile( -file => $password_ini, -key => $key ); 
$connect_params = $conn->getDBIConnectParams;

ok(    $dsn  eq $connect_params->[0]
    && $user eq $connect_params->[1]
    && $pass eq $connect_params->[2]
    && ref($connect_params->[3]) eq 'HASH'
    && exists($connect_params->[3]->{attr1}) && $connect_params->[3]->{attr1} eq 'ATTR1'
    && exists($connect_params->[3]->{attr2}) && $connect_params->[3]->{attr2} eq 'ATTR2'
        ,    'encpassw.pl with key and attrs' );

