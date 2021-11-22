#!perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use DBIx::Spreadsheet;

my $testcount = 5;

plan tests => $testcount * 2;

for my $type (qw(ods xlsx)) {
    if( !Spreadsheet::Read::parses($type)) {
        SKIP: {
            skip "$type not supported by Spreadsheet::Read, most likely a prerequisite is missing", $testcount;
        };
    };

    my $db = DBIx::Spreadsheet->new( file => "t/Accounting-test.$type" );
    my $dbh = $db->dbh;
    ok $dbh, "We fetch a dbh";
    is_deeply $db->tables, [
        { sheet => 'Invoices', table => 'Invoices' },
        { sheet => 'Expenses', table => 'Expenses' },
        { sheet => 'VAT Declaration', table => 'VAT_Declaration' },
        { sheet => 'Account', table => 'Account' },
    ], "We have the worksheets as tables";

    my $expenses = $dbh->selectall_arrayref(<<'SQL', { Slice => {} });
        select
               *
          from Expenses
SQL

    is 0+$expenses->[0]->{Amount}, 4000, "Currency symbols get stripped with $type";
    is $expenses->[0]->{Date}, '2017-03-01', "Dates get formatted as YYYY-MM-DD with $type";

    # Fix up the columns
    for my $col (qw(VAT_19_perc VAT_7_perc Amount)) {
        for my $row (@$expenses) {
            if( exists $row->{$col}
                and $row->{$col} =~ /^\d+(?:\.\d+)?$/) {
                $row->{$col} = sprintf '%2.2f', $row->{$col};
            };
        }
    };

    is_deeply $expenses, [
        {
          'Type' => 'venue',
          'Receipt_number' => '1',
          'Status' => 'paid',
          'Amount' => '4000.00',
          'VAT_19_perc' => '4760.00',
          'Company' => undef,
          'Booking_Category' => 'GPW2017',
          'Transaction_ID' => undef,
          'Vat_7_perc' => '0.00',
          'Date' => '2017-03-01'
        },
        {
          'Booking_Category' => 'GPW2017',
          'Transaction_ID' => undef,
          'Vat_7_perc' => '0.00',
          'Date' => '2017-03-02',
          'Type' => 'social event',
          'Receipt_number' => '2',
          'Status' => 'paid',
          'Amount' => '1200.00',
          'VAT_19_perc' => '1428.00',
          'Company' => undef
        },
        {
          'Type' => 'T-shirts',
          'Receipt_number' => '3',
          'Status' => 'paid',
          'VAT_19_perc' => '595.00',
          'Amount' => '500.00',
          'Company' => undef,
          'Booking_Category' => 'GPW2017',
          'Transaction_ID' => undef,
          'Date' => '2017-03-03',
          'Vat_7_perc' => '0.00'
        }
    ], "We can fetch Expenses ($type)"
        or diag Dumper $expenses;
};
