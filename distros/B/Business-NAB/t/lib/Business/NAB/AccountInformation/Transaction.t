#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::Most;
use FindBin qw/ $Bin /;
use File::Temp;
use Test::File::Contents;
use Test::Warnings;

my $class = join(
    '::',
    qw/
        Business
        NAB
        AccountInformation
        Transaction
        /,
);

use_ok( $class );

subtest 'parse' => sub {

    my $example_line = '16,495,450000,0,B,C,INTERNET TRANSFER';
    isa_ok(
        my $Transaction = $class->new_from_raw_record( $example_line ),
        $class,
    );

    is( $Transaction->transaction_code,   '495',               '->transaction_code' );
    is( $Transaction->amount_minor_units, 450000,              '->amount_minor_units' );
    is( $Transaction->funds_type,         0,                   '->funds_type' );
    is( $Transaction->bank_reference,     'B',                 '->bank_reference' );
    is( $Transaction->customer_reference, 'C',                 '->customer_reference' );
    is( $Transaction->text,               'INTERNET TRANSFER', '->text' );

    ok( $Transaction->is_debit,   '->is_debit' );
    ok( !$Transaction->is_credit, '->is_credit' );
    is( $Transaction->description, 'Transfer debits', '->description' );

    my $bad_line = $example_line =~ s/^1/2/r;

    throws_ok(
        sub { $class->new_from_raw_record( $bad_line ); },
        qr/unsupported record type \(26\)/,
    );
};

done_testing();
