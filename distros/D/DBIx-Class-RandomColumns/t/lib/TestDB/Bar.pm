package TestDB::Bar;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components('RandomColumns');

__PACKAGE__->table('bar');

__PACKAGE__->add_columns(
    id => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 20,
        is_random => 1,
    },
    string1 => {
        data_type => 'text',
        is_nullable => 0,
        size => 32,
        is_random => 1,
    },
    number1 => {
        data_type => 'int',
        is_nullable => 0,
        size => 10,
        extra => {unsigned => 1},
        is_random => {max => 2**31-1},
    },
    number2 => {
        data_type => 'int',
        is_nullable => 0,
        size => 10,
        is_random => {min => -2**31, max => 2**31-1},
    },
    number3 => {
        data_type => 'int',
        is_nullable => 0,
        size => 5,
        is_random => 1,
    },
    number4 => {
        data_type => 'int',
        is_nullable => 0,
        size => 5,
        extra => {unsigned => 1},
        is_random => {min => -5, max => 3},
    },
    number6 => {
        data_type => 'int',
        is_random => {min => -2**16, max => 2**16-1},
    },
    string3 => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 10,
        is_random => {size => 3, set => [0..9], check => 1},
    },
    string4 => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 32,
        is_random => 1,
    },
    string5 => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 32,
    },
    string6 => {
        data_type => 'varchar',
        size => 100,
        is_random => 1,
    },
    string7 => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 255,
        is_random => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['string5']);

__PACKAGE__->remove_columns(qw(string6 number6));
__PACKAGE__->remove_column('string7');

1;
