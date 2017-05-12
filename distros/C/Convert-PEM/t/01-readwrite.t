use strict;
use Test::More tests => 16;
use Test::Exception;

use Convert::PEM;
use Math::BigInt;

my $objfile = "./object.pem";

my $pem = Convert::PEM->new(
           Name => 'TEST OBJECT',
           ASN  => qq(
               TestObject SEQUENCE {
                   int INTEGER
               }
    ));
isa_ok $pem, 'Convert::PEM';

my($obj, $obj2);
$obj = { TestObject => { int => 4 } };

lives_ok { $pem->write( Filename => $objfile, Content => $obj) } 'can write';
ok -e $objfile, 'output file exists';
lives_ok { $obj2 = $pem->read( Filename => $objfile ) } 'can read';
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'input matches output';
unlink $objfile;

lives_ok { $pem->write( Filename => $objfile, Content => $obj, Password => 'xx' ) } 'can write';
ok -e $objfile, 'output file exists';
lives_ok { $obj2 = $pem->read( Filename => $objfile ) } 'can read';
ok !defined $obj2, 'cannot read encrypted file';
like $pem->errstr, qr/^Decryption failed/, 'errstr matches decryption failed';
lives_ok { $obj2 = $pem->read( Filename => $objfile, Password => 'xx') } 'can read';
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'input matches output';
unlink $objfile;

$obj->{TestObject}{int} = Math::BigInt->new("110982309809809850938509");
lives_ok { $pem->write( Filename => $objfile, Content => $obj) } 'can write';
ok -e $objfile, 'output file exists';
lives_ok { $obj2 = $pem->read( Filename => $objfile ) } 'can read';
is $obj->{TestObject}{int}, $obj2->{TestObject}{int}, 'input matches output';
unlink $objfile;
