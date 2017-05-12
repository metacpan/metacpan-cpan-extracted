#!perl -w

use Test::Simple tests => (6 * 28 + 2);

use File::Spec;
use Config::IniFiles;
use Data::Dump qw(dump);           
 
use DBIx::PasswordIniFile;

$ini_file = File::Spec->catfile('.','t','new.ini');
$config = new Config::IniFiles;


$dsn = 'dbi:driver:dbd_specific';

@tests = (   
   { -section => 'some_section', -ini => { dsn => $dsn }}
  ,{ -section => 'some_section', -ini => { dsn => $dsn, user => undef, pass => undef }}
  ,{ -section => 'some_section', -ini => { dsn => $dsn, user => 'USER', pass => 'PASS' }}
  ,{ -section => 'some_section', -ini => { dsn => $dsn, user => 'USER', pass => 'PASS', attr1 => 'ATTR1', attr2 => 'ATTR2' }}
  ,{ -section => 'connect'     , -ini => { dsn => $dsn }}
  ,{ -section => 'connect'     , -ini => { dsn => $dsn, user => undef, pass => undef }}
  ,{ -section => 'connect'     , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS' }}
  ,{ -section => 'connect'     , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS', attr1 => 'ATTR1', attr2 => 'ATTR2' }}
  ,{ -section => 'connection'  , -ini => { dsn => $dsn }}
  ,{ -section => 'connection'  , -ini => { dsn => $dsn, user => undef, pass => undef }}
  ,{ -section => 'connection'  , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS' }}
  ,{ -section => 'connection'  , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS', attr1 => 'ATTR1', attr2 => 'ATTR2' }}
  ,{ -section => 'database'    , -ini => { dsn => $dsn }}
  ,{ -section => 'database'    , -ini => { dsn => $dsn, user => undef, pass => undef }}
  ,{ -section => 'database'    , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS' }}
  ,{ -section => 'database'    , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS', attr1 => 'ATTR1', attr2 => 'ATTR2' }}
  ,{ -section => 'db'          , -ini => { dsn => $dsn }}
  ,{ -section => 'db'          , -ini => { dsn => $dsn, user => undef, pass => undef }}
  ,{ -section => 'db'          , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS' }}
  ,{ -section => 'db'          , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS', attr1 => 'ATTR1', attr2 => 'ATTR2' }}
  ,{ -section => 'dsn'         , -ini => { dsn => $dsn }}
  ,{ -section => 'dsn'         , -ini => { dsn => $dsn, user => undef, pass => undef }}
  ,{ -section => 'dsn'         , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS' }}
  ,{ -section => 'dsn'         , -ini => { dsn => $dsn, user => 'USER', pass => 'PASS', attr1 => 'ATTR1', attr2 => 'ATTR2' }}
  ,{ -section => 'virtual user', -ini => { dsn => $dsn }}
  ,{ -section => 'virtual user', -ini => { dsn => $dsn, user => undef, pass => undef }}
  ,{ -section => 'virtual user', -ini => { dsn => $dsn, user => 'USER', pass => 'PASS' }}
  ,{ -section => 'virtual user', -ini => { dsn => $dsn, user => 'USER', pass => 'PASS', attr1 => 'ATTR1', attr2 => 'ATTR2' }}
);

foreach my $t ( @tests )
{
    &createIniFile($t->{-section}, $t->{-ini});
    $pif = new DBIx::PasswordIniFile(-file => $ini_file,                          
                                     -section => $t->{-section});

    # File .ini needs encryption of pass parameter, if it exists
    #
    $pif->changePassword( $t->{-ini}->{pass} ) if $t->{-ini}->{pass};
    
    ok( ref($pif) eq 'DBIx::PasswordIniFile', 
        'new. ' . dump($t) );

    ok(    exists $pif->{config_} 
        && ref($pif->{config_})  eq 'Config::IniFiles'
 
        && exists $pif->{section_}  
        && $pif->{section_} eq $t->{-section}
 
        && exists $pif->{key_}  
 
        && exists $pif->{cipher_}  
        && $pif->{cipher_} eq 'Blowfish'
 
        && exists $pif->{dbh_}

        ,'object. ' . dump($t) );
                                                          
    $conn_params = $pif->getDBIConnectParams();
        
    if( $t->{-ini}->{pass} )
    {
        ok( $conn_params->[2] eq $t->{-ini}->{pass}, 'check password defined. ' . dump($t) );
    }
    else
    {                   
        ok( !defined($conn_params->[2]), 'check password undefined. ' . dump($t)  );
    }
    
    $pif->changePassword('new_password');
    $conn_params = $pif->getDBIConnectParams();
    
    ok( $conn_params->[2] eq 'new_password', 'changePassword. ' . dump($t) );

    # Debug:
    #diag("Debug:\n" . dump($t) . "\ngetDBIConnectParams returned:\n" . dump($conn_params));
    
    if( $t->{-ini}->{user} )
    {
        ok( $conn_params->[1] eq $t->{-ini}->{user}, 'getDBIConnectParams. check user defined. ' . dump($t) );
    }
    else          
    {  
        ok( !defined($conn_params->[1]),  'getDBIConnectParams. check user undefined. ' . dump($t));
    }               
    
    ok( DBI->parse_dsn( $conn_params->[0] ), 'getDBIConnectParams. check dsn. ' . dump($t) );
}                     
                             
# Default section doesn't exists
&createIniFile('some_section', {dsn=>$dsn} );
$pif = new DBIx::PasswordIniFile(-file => $ini_file);
ok( !defined($pif), 'default section doesn\'t exist');
                     
# File does't exists
$pif = new DBIx::PasswordIniFile( -file => 'file_does_not_exists.ini',
                                           -section => 'any_section');
ok( !defined($pif), 'File does not exists' );
   
                                                            
#-----------------------------------------------------------------------------
# Functions

# Creates a .ini file without encryption of pass parameter
#
sub createIniFile    
{
    my $section_name = shift;                                      
    my $h = shift;
    
    $config->Delete();

    $config->AddSection($section_name);

    my($par,$val);
    while( ($par,$val) = each %$h )
    {
        $config->newval($section_name,$par, defined($val) ? $val : '');
    }
    
    $config->SetFileName( $ini_file );
    $config->RewriteConfig();
}

1;
