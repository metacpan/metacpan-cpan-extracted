#!/usr/bin/perl
use v5.10;
use strict;
use warnings;

use Test::More tests => 16;
use lib "t/lib";

{
    package Test::Artifacts;
    use Bolts;

    artifact journal_entry => (
        class => 'Test::JournalEntry',
        infer => 'options',
    );

    artifact account => (
        class => 'Test::AccountBook',
        infer => 'options',
        parameters => {
            journal => builder { [] },
        },
    );

    artifact line_id => (
        builder => sub {
            state $id = 1;
            return $id++;
        },
    );

    artifact timestamp => (
        builder => sub { time },
    );

    artifact split => (
        builder => sub { [] },
    );

    artifact general_ledger => (
        class => 'Test::GeneralLedger',
        infer => 'acquisition',
    );
}

my $bag = Test::Artifacts->new;
isa_ok($bag, 'Test::Artifacts');

my $bank = $bag->acquire('account', {
    name         => 'Millionth Bank',
    account_type => 'debit',
});
isa_ok($bank, 'Test::AccountBook');
is($bank->balance, 0, 'bank balance starts at $0');

my $income = $bag->acquire('account', {
    name         => 'Fancycorp',
    account_type => 'credit',
});
isa_ok($income, 'Test::AccountBook');
is($income->balance, 0, 'income balance starts at $0');

my $ledger = $bag->acquire('general_ledger');
isa_ok($ledger, 'Test::GeneralLedger');
ok($ledger->is_balanced, 'ledger starts balanced');
ok(!$ledger->complete, 'ledger starts incomplete');

my $journal_deposit = $bag->acquire('journal_entry', {
    ledger      => $ledger,
    description => 'Deposit',
    account     => $bank,
    memo        => 'Fancycorp Paycheck',
    amount      => -10000, # DR 100.00
});
isa_ok($journal_deposit, 'Test::JournalEntry');

$bank->add_ledger($journal_deposit);
$ledger->add_ledger($journal_deposit);

is($bank->balance, '10000', 'bank balance now $100');
ok(!$ledger->is_balanced, 'ledger is now out of balance');
ok(!$ledger->complete, 'ledger is still not complete');

my $journal_check = $bag->acquire('journal_entry', {
    ledger      => $ledger,
    description => 'Fancycorp',
    account     => $income,
    memo        => 'Check #101',
    amount      => 10000, # CR 100.00
});
isa_ok($journal_check, 'Test::JournalEntry');

$income->add_ledger($journal_check);
$ledger->add_ledger($journal_check);

is($income->balance, '10000', 'income balance now $100');
ok($ledger->is_balanced, 'ledger is back in balance');
ok($ledger->complete, 'ledger is now complete');
