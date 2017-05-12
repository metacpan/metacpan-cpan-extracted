# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 09-clone-digest.t'

#########################

use Test;
use ExtUtils::testlib;
use Crypt::GCrypt;

#########################

# SHA1 progressive digests (can we read what the digest should be along the way?):

my %dgsts = (
    '' => 'da39a3ee5e6b4b0d3255bfef95601890afd80709',
    'a' => '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8',
    'abc' => 'a9993e364706816aba3e25717850c26c9cd0d89d',
    'abcdefghijklmnopqrstuvwxyz' => '32d10c7b8cf96570ca04ce37f2a19d84240d3a89',
);

plan tests => 5;

my $md0 = Crypt::GCrypt->new(
                             type => 'digest',
                             algorithm => 'sha1',
                            );
my $result;

my $md1 = $md0->clone();
$result = unpack('H*', $md1->read());
ok($result eq $dgsts{''});

$md0->write('a');

my $md2 = $md0->clone();
$result = unpack('H*', $md2->read());
ok($result eq $dgsts{'a'});

$md0->write('bc');

my $md3 = $md0->clone();
$result = unpack('H*', $md3->read());
ok($result eq $dgsts{'abc'});

$md0->write('defghijklmnopqrstuvwxyz');

my $md4 = $md0->clone();
$result = unpack('H*', $md4->read());
ok($result eq $dgsts{'abcdefghijklmnopqrstuvwxyz'});


$result = unpack('H*', $md0->read());
ok($result eq $dgsts{'abcdefghijklmnopqrstuvwxyz'});



