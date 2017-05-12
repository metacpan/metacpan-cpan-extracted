#!perl -wT
# $Id: /local/DBIx-Class-InflateColumn-Currency/t/currency.t 1669 2008-06-05T01:46:49.816545Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 254;
    };

    use_ok('Data::Currency');
    use_ok('Data::Currency::Custom');
};


my $schema = DBIC::Test->init_schema;


## Test Items, which has no class level options set
{
    my $items = $schema->resultset('Items')->search;

    is($items->count, 3);

    #[ qw/id char_currency format_currency int_currency dec_currency currency_code/ ],
    #[1,'1.23','1.23',1,1.23,undef],
    #[2,'2.34','2.34',2,2.34,'CAD'],
    #[3,'3.45','3.45',3,3.45,'NPR'],
    # int  = currency_code = 'EGP'
    # format = 'FMT_STANDARD'
    # dec  = currency_code_column = 'currency_code'


    ## load em up and check codes/formats/values
    my $item = $items->next;
    isa_ok($item, 'DBIC::TestSchema::Items');
    isa_ok($item->char_currency, 'Data::Currency::Custom');
    is($item->char_currency->code, 'USD', 'code default from Data::Currency');
    is($item->char_currency->name, 'US Dollar');
    is($item->char_currency->value, '1.23');
    is($item->char_currency, '$1.23');
    is($item->char_currency + 1, 2.23);

    isa_ok($item->format_currency, 'Data::Currency');
    is($item->format_currency->code, 'USD', 'code default from Data::Currency');
    is($item->char_currency->name, 'US Dollar');
    is($item->char_currency->value, '1.23');
    is($item->format_currency, '1.23 USD');
    is($item->format_currency + 1, 2.23);

    isa_ok($item->int_currency, 'Data::Currency');
    is($item->int_currency->code, 'EGP', 'code from currency_code attribute');
    is($item->int_currency->name, 'Egyptian Pound');
    is($item->int_currency->value, 1);
    is($item->int_currency, 'L.E. 1.00');
    is($item->int_currency + 1, 2.00);

    isa_ok($item->dec_currency, 'Data::Currency');
    is($item->dec_currency->code, 'USD', 'code from currency_code attribute');
    is($item->dec_currency->name, 'US Dollar');
    is(round($item->dec_currency->value), 1.23);
    is($item->dec_currency, '$1.23');
    is(round($item->dec_currency + 1), 2.23);

    $item = $items->next;
    isa_ok($item, 'DBIC::TestSchema::Items');
    isa_ok($item->char_currency, 'Data::Currency::Custom');
    is($item->char_currency->code, 'USD', 'code default from Data::Currency');
    is($item->char_currency->name, 'US Dollar');
    is($item->char_currency->value, '2.34');
    is($item->char_currency, '$2.34');
    is($item->char_currency + 1, 3.34);

    isa_ok($item->format_currency, 'Data::Currency');
    is($item->format_currency->code, 'USD', 'code default from Data::Currency');
    is($item->format_currency->name, 'US Dollar');
    is($item->format_currency->value, '2.34');
    is($item->format_currency, '2.34 USD');
    is($item->format_currency + 1, 3.34);

    isa_ok($item->int_currency, 'Data::Currency');
    is($item->int_currency->code, 'EGP', 'code from currency_code attribute');
    is($item->int_currency->name, 'Egyptian Pound');
    is($item->int_currency->value, 2);
    is($item->int_currency, 'L.E. 2.00');
    is($item->int_currency + 1, 3.00);

    isa_ok($item->dec_currency, 'Data::Currency');
    is($item->dec_currency->code, 'CAD', 'code from currency_code attribute');
    is($item->dec_currency->name, 'Canadian Dollar', 'This might fail due to core Locale w/msipelling');
    is(round($item->dec_currency->value), 2.34);
    is($item->dec_currency, '$2.34');
    is(round($item->dec_currency + 1), 3.34);

    $item = $items->next;
    isa_ok($item, 'DBIC::TestSchema::Items');
    isa_ok($item->char_currency, 'Data::Currency::Custom');
    is($item->char_currency->code, 'USD', 'code default from Data::Currency');
    is($item->char_currency->name, 'US Dollar');
    is($item->char_currency->value, '3.45');
    is($item->char_currency, '$3.45');
    is($item->char_currency + 1, 4.45);

    isa_ok($item->format_currency, 'Data::Currency');
    is($item->format_currency->code, 'USD', 'code default from Data::Currency');
    is($item->format_currency->name, 'US Dollar');
    is($item->format_currency->value, '3.45');
    is($item->format_currency, '3.45 USD');
    is($item->format_currency + 1, 4.45);

    isa_ok($item->int_currency, 'Data::Currency');
    is($item->int_currency->code, 'EGP', 'code from currency_code attribute');
    is($item->int_currency->name, 'Egyptian Pound');
    is($item->int_currency->value, 3);
    is($item->int_currency, 'L.E. 3.00');
    is($item->int_currency + 1, 4.00);

    isa_ok($item->dec_currency, 'Data::Currency');
    is($item->dec_currency->code, 'NPR', 'code from currency_code attribute');
    is($item->dec_currency->name, 'Nepalese Rupee');
    is(round($item->dec_currency->value), 3.45);
    is($item->dec_currency, 'Rs. 3.45');
    is(round($item->dec_currency + 1), 4.45);


    ## create with values
    my $row1 = $schema->resultset('Items')->create({
        char_currency    => '4.56',
        format_currency  => '4.56',
        int_currency     => 4,
        dec_currency     => 4.56,
        currency_code    => 'PHP'
    });

    isa_ok($row1, 'DBIC::TestSchema::Items');
    isa_ok($row1->char_currency, 'Data::Currency::Custom');
    is($row1->char_currency->code, 'USD', 'code default from Data::Currency');
    is($row1->char_currency->name, 'US Dollar');
    is($row1->char_currency->value, '4.56');
    is($row1->char_currency, '$4.56');
    is($row1->char_currency + 1, 5.56);

    isa_ok($row1->format_currency, 'Data::Currency');
    is($row1->format_currency->code, 'USD', 'code default from Data::Currency');
    is($row1->format_currency->name, 'US Dollar');
    is($row1->format_currency->value, '4.56');
    is($row1->format_currency, '4.56 USD');
    is($row1->format_currency + 1, 5.56);

    isa_ok($row1->int_currency, 'Data::Currency');
    is($row1->int_currency->code, 'EGP', 'code from currency_code attribute');
    is($row1->int_currency->name, 'Egyptian Pound');
    is($row1->int_currency->value, 4);
    is($row1->int_currency, 'L.E. 4.00');
    is($row1->int_currency + 1, 5.00);

    isa_ok($row1->dec_currency, 'Data::Currency');
    is($row1->dec_currency->code, 'PHP', 'code from currency_code attribute');
    is($row1->dec_currency->name, 'Philippine Peso');
    is(round($row1->dec_currency->value), 4.56);
    is($row1->dec_currency, 'PHP4.56');
    is(round($row1->dec_currency + 1), 5.56);


    ## create with objects/deflate
    my $row2 = $schema->resultset('Items')->create({
        char_currency    => Data::Currency::Custom->new('5.67'),
        format_currency  => Data::Currency->new('5.67'),
        int_currency     => Data::Currency->new(5),
        dec_currency     => Data::Currency->new(5.67),
        currency_code    => 'MTL'
    });

    isa_ok($row2, 'DBIC::TestSchema::Items');
    isa_ok($row2->char_currency, 'Data::Currency::Custom');
    is($row2->char_currency->code, 'USD', 'code default from Data::Currency');
    is($row2->char_currency->name, 'US Dollar');
    is($row2->char_currency->value, '5.67');
    is($row2->char_currency, '$5.67');
    is($row2->char_currency + 1, 6.67);

    isa_ok($row2->format_currency, 'Data::Currency');
    is($row2->format_currency->code, 'USD', 'code default from Data::Currency');
    is($row2->format_currency->name, 'US Dollar');
    is($row2->format_currency->value, '5.67');
    is($row2->format_currency, '$5.67', 'format from object');
    is($row2->format_currency + 1, 6.67);

    isa_ok($row2->int_currency, 'Data::Currency');
    is($row2->int_currency->code, 'USD', 'code from object');
    is($row2->int_currency->name, 'US Dollar', 'name from object, not inflate');
    is($row2->int_currency->value, 5);
    is($row2->int_currency, '$5.00', 'from object not inflate');
    is($row2->int_currency + 1, 6.00);

    isa_ok($row2->dec_currency, 'Data::Currency');
    is($row2->dec_currency->code, 'USD', 'code from object not inflate');
    is($row2->dec_currency->name, 'US Dollar');
    is(round($row2->dec_currency->value), 5.67);
    is($row2->dec_currency, '$5.67');
    is(round($row2->dec_currency + 1), 6.67);
};


## Test Prices, which has class level accessors set
{
    my $prices = $schema->resultset('Prices')->search;
    is($prices->count, 3);


    ## load em up and check codes/formats/values
    ## TZS, FMT_NAME, Data::Currency::Custom
    # [1,'1.23','1.23',1,1.23,undef]
    my $price = $prices->next;
    isa_ok($price, 'DBIC::TestSchema::Prices');
    isa_ok($price->char_currency, 'Data::Currency');
    is($price->char_currency->code, 'TZS', 'code default from class');
    is($price->char_currency->name, 'Tanzanian Shilling');
    is($price->char_currency->value, '1.23');
    is($price->char_currency, '1.23 Tanzanian Shilling');
    is($price->char_currency + 1, 2.23);

    isa_ok($price->format_currency, 'Data::Currency::Custom');
    is($price->format_currency->code, 'TZS', 'code default from class');
    is($price->char_currency->name, 'Tanzanian Shilling');
    is($price->char_currency->value, '1.23');
    is($price->format_currency, '1.23 TZS');
    is($price->format_currency + 1, 2.23);

    isa_ok($price->int_currency, 'Data::Currency::Custom');
    is($price->int_currency->code, 'EGP', 'code from currency_code attribute');
    is($price->int_currency->name, 'Egyptian Pound');
    is($price->int_currency->value, 1);
    is($price->int_currency, '1 Egyptian Pound');
    is($price->int_currency + 1, 2.00);

    isa_ok($price->dec_currency, 'Data::Currency::Custom');
    is($price->dec_currency->code, 'TZS', 'code from class');
    is($price->dec_currency->name, 'Tanzanian Shilling');
    is(round($price->dec_currency->value), 1.23);
    is($price->dec_currency, '1.23 Tanzanian Shilling');
    is(round($price->dec_currency + 1), 2.23);

    $price = $prices->next;
    isa_ok($price, 'DBIC::TestSchema::Prices');
    isa_ok($price->char_currency, 'Data::Currency');
    is($price->char_currency->code, 'CAD', 'code default from currency column');
    is($price->char_currency->name, 'Canadian Dollar');
    is($price->char_currency->value, '2.34');
    is($price->char_currency, '2.34 Canadian Dollar');
    is($price->char_currency + 1, 3.34);

    isa_ok($price->format_currency, 'Data::Currency::Custom');
    is($price->format_currency->code, 'CAD', 'code default from Data::Currency');
    is($price->format_currency->name, 'Canadian Dollar');
    is($price->format_currency->value, '2.34');
    is($price->format_currency, '2.34 CAD');
    is($price->format_currency + 1, 3.34);

    isa_ok($price->int_currency, 'Data::Currency::Custom');
    is($price->int_currency->code, 'CAD', 'code from currency_code attribute');
    is($price->int_currency->name, 'Canadian Dollar');
    is($price->int_currency->value, 2);
    is($price->int_currency, '2 Canadian Dollar');
    is($price->int_currency + 1, 3.00);

    isa_ok($price->dec_currency, 'Data::Currency::Custom');
    is($price->dec_currency->code, 'CAD', 'code from currency_code attribute');
    is($price->dec_currency->name, 'Canadian Dollar', 'This might fail due to core Locale w/msipelling');
    is(round($price->dec_currency->value), 2.34);
    is($price->dec_currency, '2.34 Canadian Dollar');
    is(round($price->dec_currency + 1), 3.34);

    $price = $prices->next;
    isa_ok($price, 'DBIC::TestSchema::Prices');
    isa_ok($price->char_currency, 'Data::Currency');
    is($price->char_currency->code, 'NPR', 'code default from Data::Currency');
    is($price->char_currency->name, 'Nepalese Rupee');
    is($price->char_currency->value, '3.45');
    is($price->char_currency, '3.45 Nepalese Rupee');
    is($price->char_currency + 1, 4.45);

    isa_ok($price->format_currency, 'Data::Currency::Custom');
    is($price->format_currency->code, 'NPR', 'code default from Data::Currency');
    is($price->format_currency->name, 'Nepalese Rupee');
    is($price->format_currency->value, '3.45');
    is($price->format_currency, '3.45 NPR');
    is($price->format_currency + 1, 4.45);

    isa_ok($price->int_currency, 'Data::Currency::Custom');
    is($price->int_currency->code, 'NPR', 'code from currency_code attribute');
    is($price->int_currency->name, 'Nepalese Rupee');
    is($price->int_currency->value, 3);
    is($price->int_currency, '3 Nepalese Rupee');
    is($price->int_currency + 1, 4.00);

    isa_ok($price->dec_currency, 'Data::Currency::Custom');
    is($price->dec_currency->code, 'NPR', 'code from currency_code attribute');
    is($price->dec_currency->name, 'Nepalese Rupee');
    is(round($price->dec_currency->value), 3.45);
    is($price->dec_currency, '3.45 Nepalese Rupee');
    is(round($price->dec_currency + 1), 4.45);


    ## create with values
    my $row1 = $schema->resultset('Prices')->create({
        char_currency    => '4.56',
        format_currency  => '4.56',
        int_currency     => 4,
        dec_currency     => 4.56,
        currency_code    => 'PHP'
    });

    isa_ok($row1, 'DBIC::TestSchema::Prices');
    isa_ok($row1->char_currency, 'Data::Currency');
    is($row1->char_currency->code, 'PHP', 'code default from Data::Currency');
    is($row1->char_currency->name, 'Philippine Peso');
    is($row1->char_currency->value, '4.56');
    is($row1->char_currency, '4.56 Philippine Peso');
    is($row1->char_currency + 1, 5.56);

    isa_ok($row1->format_currency, 'Data::Currency::Custom');
    is($row1->format_currency->code, 'PHP', 'code default from Data::Currency');
    is($row1->format_currency->name, 'Philippine Peso');
    is($row1->format_currency->value, '4.56');
    is($row1->format_currency, '4.56 PHP');
    is($row1->format_currency + 1, 5.56);

    isa_ok($row1->int_currency, 'Data::Currency::Custom');
    is($row1->int_currency->code, 'PHP', 'code from currency_code attribute');
    is($row1->int_currency->name, 'Philippine Peso');
    is($row1->int_currency->value, 4);
    is($row1->int_currency, '4 Philippine Peso');
    is($row1->int_currency + 1, 5.00);

    isa_ok($row1->dec_currency, 'Data::Currency::Custom');
    is($row1->dec_currency->code, 'PHP', 'code from currency_code attribute');
    is($row1->dec_currency->name, 'Philippine Peso');
    is(round($row1->dec_currency->value), 4.56);
    is($row1->dec_currency, '4.56 Philippine Peso');
    is(round($row1->dec_currency + 1), 5.56);


    ## create with objects/deflate
    my $row2 = $schema->resultset('Prices')->create({
        char_currency    => Data::Currency->new('5.67'),
        format_currency  => Data::Currency::Custom->new('5.67'),
        int_currency     => Data::Currency::Custom->new(5),
        dec_currency     => Data::Currency::Custom->new(5.67),
        currency_code    => 'MTL'
    });

    isa_ok($row2, 'DBIC::TestSchema::Prices');
    isa_ok($row2->char_currency, 'Data::Currency');
    is($row2->char_currency->code, 'USD', 'code default from Data::Currency');
    is($row2->char_currency->name, 'US Dollar');
    is($row2->char_currency->value, '5.67');
    is($row2->char_currency, '$5.67');
    is($row2->char_currency + 1, 6.67);

    isa_ok($row2->format_currency, 'Data::Currency::Custom');
    is($row2->format_currency->code, 'USD', 'code default from Data::Currency');
    is($row2->format_currency->name, 'US Dollar');
    is($row2->format_currency->value, '5.67');
    is($row2->format_currency, '$5.67', 'format from object');
    is($row2->format_currency + 1, 6.67);

    isa_ok($row2->int_currency, 'Data::Currency::Custom');
    is($row2->int_currency->code, 'USD', 'code from object');
    is($row2->int_currency->name, 'US Dollar', 'name from object, not inflate');
    is($row2->int_currency->value, 5);
    is($row2->int_currency, '$5.00', 'from object not inflate');
    is($row2->int_currency + 1, 6.00);

    isa_ok($row2->dec_currency, 'Data::Currency::Custom');
    is($row2->dec_currency->code, 'USD', 'code from object not inflate');
    is($row2->dec_currency->name, 'US Dollar');
    is(round($row2->dec_currency->value), 5.67);
    is($row2->dec_currency, '$5.67');
    is(round($row2->dec_currency + 1), 6.67);
};

sub round {
    my ($number, $precision) = @_;
    
    $precision = 2 unless defined $precision;
    $number    = 0 unless defined $number;

    my $sign = $number <=> 0;
    my $multiplier = (10 ** $precision);
    my $result = abs($number);
    $result = int(($result * $multiplier) + .5000001) / $multiplier;
    $result = -$result if $sign < 0;
    return $result;
}
