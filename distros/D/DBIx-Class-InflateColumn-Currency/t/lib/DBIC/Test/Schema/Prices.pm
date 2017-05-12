# $Id: /local/DBIx-Class-InflateColumn-Currency/t/lib/DBIC/Test/Schema/Prices.pm 1283 2007-03-05T23:04:49.799305Z claco  $
package DBIC::Test::Schema::Prices;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;
};

__PACKAGE__->load_components(qw/InflateColumn::Currency Core/);
__PACKAGE__->table('prices');
__PACKAGE__->source_name('Prices');
__PACKAGE__->currency_code('TZS');
__PACKAGE__->currency_format('FMT_NAME | FMT_NOZEROS');
__PACKAGE__->currency_code_column('currency_code');
__PACKAGE__->currency_class('Data::Currency::Custom');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => {unsigned => 1}
    },
    char_currency => {
        data_type      => 'VARCHAR',
        size           => 25,
        is_nullable    => 0,
        is_currency    => 1,
        currency_class => 'Data::Currency'
    },
    format_currency => {
        data_type       => 'VARCHAR',
        size            => 25,
        is_nullable     => 0,
        is_currency     => 1,
        currency_format => 'FMT_STANDARD'
    },
    int_currency => {
        data_type      => 'INT',
        size           => 3,
        is_nullable    => 0,
        extras         => {unsigned => 1},
        is_currency    => 1,
        currency_code  => 'EGP'
    },
    dec_currency => {
        data_type            => 'DECIMAL',
        size                 => [9,2],
        is_nullable          => 0,
        is_currency          => 1,
        currency_code_column => 'currency_code'
    },
    currency_code => {
        data_type     => 'VARCHAR',
        size          => 3,
        is_nullable   => 1
    }
);
__PACKAGE__->set_primary_key('id');

1;
