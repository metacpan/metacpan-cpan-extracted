use strict;
use Test::More tests => 14;

use Convert::ASN1;
use Convert::PEM;

my($str1,$str2) = (pack('H*','3003020104'),pack('H*','300c020a17805cf22a8b3270b48d'));

my $desc = qq(
               TestObject SEQUENCE {
                   int INTEGER
               }
    );

#### create object with DER InForm and OutForm to test for proper behavior

my $asn = Convert::ASN1->new()->prepare($desc);
my $pem = Convert::PEM->new(
           Name => 'TEST OBJECT',
		   InForm => 'DER',
		   OutForm => 'DER' );

isa_ok $pem, 'Convert::PEM';

my($obj, $obj2, $blob);

$blob = $pem->encode( DER => $str1, );
ok $blob, 'encode gave us something';
note($blob);
$obj2 = $pem->decode( Content => $blob, );
is $obj2, $str1, 'input matches output';

$blob = $pem->encode( DER => $str1, Password => 'xx', IV => '3EC5575B0B86C70E' );
ok !$pem->error(), 'no error after encode with IV'.($pem->error() ? ": ".$pem->error() : '');
note($blob);
ok $blob, 'encode gave us something';
$obj2 = $pem->decode( Content => $blob );
ok !defined $obj2, 'decode fails on encrypted input';
like $pem->errstr, qr/^Decryption failed/, 'errstr of "'.$pem->errstr.'" matches decrypt failed';
$obj2 = $pem->decode( Content => $blob, Password => 'xx' );
is $obj2, $str1, 'input matches output';

$blob = $pem->encode( DER => $str2 );
ok $blob, 'encode gave us something';
note($blob);
$obj2 = $pem->decode( Content => $blob );
is $obj2, $str2, 'input matches output';

#### optional DER encoding

my $pem = Convert::PEM->new(
           Name => 'TEST OBJECT',
		   ASN  => $desc,
		   InForm => 'DER',
		   OutForm => 'DER' );

$obj = $asn->decode($str1);

$blob = $pem->encode( Content => $obj );
ok $blob, 'encode Content gave us something';
$obj2 = $pem->decode( Content => $blob, );
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'encode Content input matches decode Content output';

$blob = $pem->encode( DER => $str1 );
ok $blob, 'encode DER gave us something';

$obj2 = $pem->decode( Content => $blob, );
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'encode Content input matches decode Content output';
