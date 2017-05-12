#!perl -w

use Test::Simple tests => 10;

use DBIx::PasswordIniFile;
use Config::IniFiles;
use File::Spec;

$cfg = new Config::IniFiles;
$cfg->AddSection( 'connection ' );
$cfg->newval('connection', 'pass', '--------');
$cfg->SetFileName( File::Spec->catfile('.','t','password.ini') );
$cfg->RewriteConfig();

$conn = new DBIx::PasswordIniFile(
            -file => File::Spec->catfile('.','t','password.ini') );

#----------------------------------------------
# Test default key read
#----------------------------------------------

ok( $conn->{key_}, 'Default key read' );

#----------------------------------------------
# Test for encryptPassword and decryptPassword
#----------------------------------------------

$pass = 'this is my password';
$encrypt_pass = $conn->encryptPassword($pass);
$decrypt_pass = $conn->decryptPassword($encrypt_pass);
ok($decrypt_pass eq $pass, 'encryptPassword and decryptPassword w/ passw lenght > 0');

$pass = '';
$encrypt_pass = $conn->encryptPassword($pass);
$decrypt_pass = $conn->decryptPassword($encrypt_pass);
ok($decrypt_pass eq $pass, 'encryptPassword and decryptPassword w/ passw lenght == 0');

#----------------------------------------------
# Test for changePassword
#----------------------------------------------

# Test changePassword with a non-empty password

$pass = 'this is my password';
$encrypt_pass = $conn->changePassword($pass);

$cfg->ReadConfig(); # Required after a setval and before a val

ok($pass eq $conn->decryptPassword($encrypt_pass), 'changePassword encrypts ok');
ok($encrypt_pass eq $cfg->val('connection','pass'), 'changePassword saves ok');
ok($pass eq $conn->decryptPassword($cfg->val('connection','pass')),'changePassword w/ length > 0');

$cfg->setval('connection','pass','--------');
$cfg->RewriteConfig();
$cfg->ReadConfig();

# Test changePassword with an empty password

$pass = '';
$encrypt_pass = $conn->changePassword($pass,$cfg);

$cfg->ReadConfig(); # Required after a setval and before a val

ok($pass eq $conn->decryptPassword($encrypt_pass), 'changePassword encrypts ok w/ blank password');
ok($encrypt_pass eq $cfg->val('connection','pass'), 'changePassword saves ok w/ blank passw');
ok($pass eq $conn->decryptPassword($cfg->val('connection','pass')),'changePassword w/ length == 0');

# Test encription and decription with different 
# keys

$pass = 'this is a clear password';
$encrypt_pass = $conn->changePassword($pass);

$conn = new DBIx::PasswordIniFile(
            -file => File::Spec->catfile('.','t','password.ini'),
            -key  => 'this is a new key'
        );

ok($pass ne $conn->decryptPassword($encrypt_pass), 'encrypt/decrypt w/ different keys');

