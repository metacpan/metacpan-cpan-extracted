package My::Product;

use base 'My::Table';

sub data_order
{
    [
     {
         column => 'PRODNAME',
         type   => 'VARCHAR',
         length => '30',
         opts   => 'NOT NULL',
     },
     {
         column => 'BASEPRICE',
         type   => 'DECIMAL',
         length => '8,2',
     },
     { 
         column => 'PRODID',
         type   => 'INTEGER',
         generatedidentity => undef,
     },
    ];
};

sub get_base_row_type { 'My::Row' };

1;
