#!/usr/bin/perl
use v5.10;
use strict;
use warnings;

use Test::More tests => 20;
use lib "t/lib";

{
    package Test::Artifacts;
    use Bolts;

    use Moose::Util::TypeConstraints;

    artifact journal_entry => (
        class => 'Test::JournalEntry',
        parameters => {
            ledger => option {
                isa      => 'Test::GeneralLedger',
                required => 1,
            },
            description => option {
                isa      => 'Str',
                required => 1,
            },
            account => option {
                isa      => 'Test::AccountBook',
                required => 1,
            },
            amount => option {
                isa      => 'Int',
                required => 1,
            },
        },
        setters => {
            memo => option {
                isa      => 'Str',
            },
        },
    );

    artifact account => (
        class => 'Test::AccountBook',
        parameters => {
            name => option {
                isa      => 'Str',
                required => 1,
            },
            account_type => option {
                isa      => enum([ 'debit', 'credit' ]),
                required => 1,
            },
            journal => builder { [] },
        },
    );

    artifact line_id => (
        builder => sub {
            state $id = 1;
            return $id++;
        },
    );

    artifact now => (
        builder => sub { time },
    );

    artifact empty_list => (
        builder => sub { [] },
    );

    artifact general_ledger => (
        class => 'Test::GeneralLedger',
        parameters => {
            line_id   => dep('line_id'),
            timestamp => dep('now'),
            split     => dep('empty_list'),
        },
    );

    artifact array_indexes => (
        builder => sub { [ 'test', 'test' ] },
        indexes => [ 
            1 => value 'foo',
            4 => value 'bar',
            5 => value 'baz',
            7 => value 'qux',
        ],
    );

    artifact array_push => (
        builder => sub { [ 'test', 'test' ] },
        push => [ 
            value 'foo',
            value 'bar',
            value 'baz',
            value 'qux',
        ],
    );

    artifact hash => (
        builder => sub { +{ foo => 1, test => 2 } },
        keys => {
            foo => value 42,
            bar => value 43,
            baz => value 94,
            qux => value 107,
        },
    );
}

my $bag = Test::Artifacts->new;
isa_ok($bag, 'Test::Artifacts');

# And now for something completely different...
{
    my $a1 = $bag->acquire('array_indexes');
    is_deeply($a1, [ 'test', 'foo', undef, undef, 'bar', 'baz', undef, 'qux' ], 'array index injection is ok');

    my $a2 = $bag->acquire('array_push');
    is_deeply($a2, [ qw( test test foo bar baz qux ) ], 'array push injection is ok');

    my $h = $bag->acquire('hash');
    is_deeply($h, {
        test => 2,
        foo  => 42,
        bar  => 43,
        baz  => 94,
        qux  => 107,
    }, 'hash key injection is ok');
}

my $bank = $bag->acquire('account', {
    name         => 'Millionth Bank',
    account_type => 'debit',
});
isa_ok($bank, 'Test::AccountBook');
is($bank->balance, 0, 'bank balance starts at $0');

eval {
    my $broke = $bag->acquire('account', {
        name         => 'Broke',
        account_type => 'something_else',
    });
};

like($@, qr{^Value for injection }, 'parameters check type');

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
