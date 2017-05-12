#!/usr/bin/env perl

use Test::More tests => 9;
use Math::BigInt try => 'GMP,Pari';
use strict;
use warnings;
no strict 'refs';

use lib '../lib';

our $module;
BEGIN {
    our $module = 'Crypt::MagicSignatures::Key';
    use_ok($module, qw/b64url_encode b64url_decode/);   # 1
};

# test from http://cpansearch.perl.org/src/VIPUL/Crypt-RSA-1.99/t/01-i2osp.t
my $number = 4;
my $i2osp = *{"${module}::_i2osp"}->($number, 4);
my $os2ip = *{"${module}::_os2ip"}->($i2osp);

is($os2ip, $number, 'Crypt::RSA::Test i2osp and os2ip - 1');

$number = '1234857092384759348579032847529875982374'.
    '5092384759238475903248759238475246534653984765'.
    '8327456823746587342658736587324658736453548634'.
    '9864390323422374897503987560374089721346786456'.
    '7836498734612897468237648745698743648796487932'.
    '6487964378569287346529';
$i2osp = *{"${module}::_i2osp"}->($number, 102);
$os2ip = *{"${module}::_os2ip"}->($i2osp);

is($os2ip, $number, 'Crypt::RSA::Test i2osp and os2ip - 2');

my $string = 'abcdefghijklmnopqrstuvwxyz-'.
    '0123456789-abcdefghijklmnopqrstuvwxy'.
    'z-abcdefghijklmnopqrstuvwxyz-0123456'.
    '789';
$number = Math::BigInt->new('166236188672784693770242514753'.
			    '420034912412776787232632921068'.
			    '824014646347893937590064771712'.
			    '921923774969379936913356439094'.
			    '695954550320707099033382274920'.
			    '372913421785829711983357001510'.
			    '792400267452442816935867829132'.
			    '703234881800415259286201953001'.
			    '355321');

$os2ip = *{"${module}::_os2ip"}->($string);

is($os2ip, $number, 'Crypt::RSA::Test i2osp and os2ip - 3');

$i2osp = *{"${module}::_i2osp"}->($os2ip);

is($i2osp, $string, 'Crypt::RSA::Test i2osp and os2ip - 4');

$i2osp = *{"${module}::_i2osp"}->($number);

is($i2osp, $string, 'Crypt::RSA::Test i2osp and os2ip - 5');

$string = "abcd";
$number = 1_633_837_924;

$os2ip = *{"${module}::_os2ip"}->($string);

is($os2ip, $number, 'Crypt::RSA::Test i2osp and os2ip - 6');

$i2osp = *{"${module}::_i2osp"}->($os2ip);

is($i2osp, $string, 'Crypt::RSA::Test i2osp and os2ip - 7');

$i2osp = *{"${module}::_i2osp"}->($number);

is($i2osp, $string, 'Crypt::RSA::Test i2osp and os2ip - 8');
