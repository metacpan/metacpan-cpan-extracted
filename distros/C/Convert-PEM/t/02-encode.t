use strict;
use Test::More tests => 8;

use Convert::PEM;
use Math::BigInt;

my $pem = Convert::PEM->new(
           Name => 'TEST OBJECT',
           ASN  => qq(
               TestObject SEQUENCE {
                   int INTEGER
               }
    ));
isa_ok $pem, 'Convert::PEM';

my($obj, $obj2, $blob);
$obj = { TestObject => { int => 4 } };

$blob = $pem->encode( Content => $obj );
ok $blob, 'encode gave us something';
$obj2 = $pem->decode( Content => $blob );
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'input matches output';

$blob = $pem->encode( Content => $obj, Password => 'xx' );
ok $blob, 'encode gave us something';
$obj2 = $pem->decode( Content => $blob );
ok !defined $obj2, 'decode fails on encrypted input';
$obj2 = $pem->decode( Content => $blob, Password => 'xx' );
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'input matches output';

$obj->{TestObject}{int} = Math::BigInt->new("110982309809809850938509");
$blob = $pem->encode( Content => $obj );
ok $blob, 'encode gave us something';
$obj2 = $pem->decode( Content => $blob );
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'input matches output';
