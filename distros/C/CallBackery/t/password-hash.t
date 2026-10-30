use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;
use utf8;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);
use Mojo::Util qw(hmac_sha1_sum);
use Crypt::ScryptKDF qw(scrypt_hash);
use Encode qw(encode_utf8);
use Unicode::Normalize qw(NFC NFD);

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');
my $db = $t->app->database;
my $bob = $db->updateOrInsertData('cbuser',{login => 'bob', family => 'B', given => 'B', password => hmac_sha1_sum('bobpw')});
my $login = sub { $t->app->userObject->new(app => $t->app)->login(@_) };

ok !$login->('bob','wrong'), 'a wrong password is refused';
ok $login->('bob','bobpw'), 'a user with an old password hash can log in';
like $db->fetchValue('cbuser',{id => $bob},'password'), qr/^SCRYPT:/, 'and the hash is replaced with a scrypt hash';
ok $login->('bob','bobpw') && !$login->('bob','wrong'), 'the scrypt hash checks the password';

my $user = $t->app->userObject->new(app => $t->app);
my $pw = NFC('Grüße 🔑');
my $ann = $db->updateOrInsertData('cbuser',{login => 'ann', family => 'A', given => 'A', password => $user->hashPassword($pw)});
ok $login->('ann',$pw), 'a password outside Latin-1 logs in';
ok $login->('ann',NFD($pw)), 'also when the client sends it decomposed';

# hin-agw-appliance stores scrypt_hash(encode_utf8(NFC($password)))
$db->updateOrInsertData('cbuser',{password => scrypt_hash(encode_utf8($pw))},{id => $ann});
ok $login->('ann',$pw), 'a hash in the hin-agw-appliance format logs in';

$db->updateOrInsertData('cbuser',{password => $user->hashPassword('x')},{id => $ann});
$db->updateOrInsertData('cbuser',{login => 'odd', family => 'O', given => 'O', password => '$2b$10$unknownformat'});
ok !$login->('odd',$_), "a hash in an unknown format does not log in with '$_'" for 'x', '$2b$10$unknownformat';

my $checks = 0;
my $verify = \&CallBackery::User::scrypt_hash_verify;
no warnings 'redefine';
local *CallBackery::User::scrypt_hash_verify = sub { $checks++; goto &$verify };
$db->updateOrInsertData('cbuser',{login => 'old', family => 'O', given => 'O', password => hmac_sha1_sum('oldpw')});
is_deeply [map { $checks = 0; $login->(@$_); $checks } ['nobody','x'], ['bob',''], ['bob','wrong'], ['old','wrong']],
    [1,1,1,1], 'every failed login costs one scrypt check, so its time does not tell whether the user exists';

done_testing();
