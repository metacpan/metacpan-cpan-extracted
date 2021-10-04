#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 10;
use Test::Exception;
use BankAccount::Validator::UK;


ok(BankAccount::Validator::UK->new(debug => 1));

my $account = BankAccount::Validator::UK->new();
isa_ok($account, 'BankAccount::Validator::UK');
can_ok('BankAccount::Validator::UK', qw/is_valid get_trace/);

throws_ok { $account->is_valid() } qr/ERROR: Missing bank sort code./, 'error caught okay';
throws_ok { $account->is_valid(123456) } qr/ERROR: Missing bank account number./, 'error caught okay';
throws_ok { $account->is_valid('ab3456', 12345678) } qr/ERROR: Invalid bank sort code./, 'error caught okay';
throws_ok { $account->is_valid('1234', 12345678) } qr/ERROR: Invalid sort code./, 'error caught okay';
throws_ok {$account->is_valid('123456', 'abcd5678') } qr/ERROR: Invalid bank account number./, 'error caught okay';
throws_ok {$account->is_valid('123456', '1234') } qr/ERROR: Invalid account number./, 'error caught okay';

$account->is_valid('871427', '09123496');
my $exp = [{ 'tot' => 121, 'ex' => 10, 'rem' => 0, 'res' => 'PASS', 'mod' => 'MOD11' }];
my $got = $account->get_trace();
is_deeply($got, $exp);

done_testing();
