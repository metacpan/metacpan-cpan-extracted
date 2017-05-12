# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01-use.t'

#########################

use Test;
BEGIN { plan tests => 20 }; # <--- number of tests

use ExtUtils::testlib;
use Crypt::GCrypt;
ok(1);

#########################

ok(Crypt::GCrypt::cipher_algo_available('aes'));
ok(Crypt::GCrypt::cipher_algo_available('arcfour'));
ok(Crypt::GCrypt::cipher_algo_available('twofish'));

my $c = Crypt::GCrypt->new(
                           type => 'cipher',
                           algorithm => 'aes',
                           mode => 'cbc',
                           padding => 'null'
);
ok(defined $c && $c->isa('Crypt::GCrypt'));
ok($c->keylen == 16);
ok($c->blklen == 16);

$c->start('encrypting');
$c->setkey(my $key = "the key, the key");

my $p = 'plain text';
my ($e0, $e, $d);
$e0 = pack('H*', 'c796843558cefa157bf108ab79823a5a');
$e = $c->encrypt($p);
$e .= $c->finish;
ok($e eq $e0) or print STDERR "[",unpack('H*',$e),"]\n";

$c->setiv();
$c->start('decrypting');
$d = $c->decrypt($e);
$d .= $c->finish;
ok(substr($d, 0, length $p) eq $p)
  or print STDERR "[",unpack('H*',$d),"]\n";;

$c = Crypt::GCrypt->new(
                        type => 'cipher',
                        algorithm => 'aes',
                        mode => 'ecb',
                        padding => 'null'
);
$c->start('encrypting');
$c->setkey($key);
$e = $c->encrypt($p);
$e .= $c->finish;
ok($e eq $e0) or print STDERR "[",unpack('H*',$e),"]\n";

$c = Crypt::GCrypt->new(
                        type => 'cipher',
                        algorithm => 'twofish',
                        padding => 'null'
);
ok($c->keylen == 32);
ok($c->blklen == 16);
$c->start('encrypting');
$c->setkey($key);
$c->setiv(my $iv = 'explicit iv');
$e = $c->encrypt($p);
$e .= $c->finish;
ok($e eq pack('H*', '9c93705d7b3348c73cd2047ce5ecc1a8'))
  or print STDERR "[",unpack('H*',$e),"]\n";
$c->start('decrypting');
$c->setiv($iv);
$d = $c->decrypt($e);
$d .= $c->finish;
ok(substr($d, 0, length $p) eq $p)
 or print STDERR "[$d|",unpack('H*',$d),"]\n";

$c = Crypt::GCrypt->new(
                        type => 'cipher',
                        algorithm => 'arcfour',
                        padding => 'null'
);
ok($c->keylen == 16);
ok($c->blklen == 1);
$c->start('encrypting');
$c->setkey($key);
$e = $c->encrypt($p);
ok($e eq pack('H*', '02a98d20a176729ea7cd'))
  or print STDERR "[",unpack('H*',$e),"]\n";
$c->setkey($key);
$c->start('decrypting');
$d = $c->decrypt($e);
$d .= $c->finish;
ok(substr($d, 0, length $p) eq $p)
 or print STDERR "[$d|",unpack('H*',$d),"]\n";

### 'none' padding
{
    $c = Crypt::GCrypt->new(
                            type => 'cipher',
                            algorithm => 'aes',
                            padding => 'none'
    );
    $c->start('encrypting');
    ok(!eval {my $e2 = $c->encrypt('aaa'); 1});  # this should die
    ok(eval { my $e2 = $c->encrypt('aaaaaaaaaaaaaaaa') . $c->finish; 1 });  # this should not die
}

