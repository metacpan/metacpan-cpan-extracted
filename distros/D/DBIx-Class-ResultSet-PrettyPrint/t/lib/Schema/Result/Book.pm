package  # hide from PAUSE
    Schema::Result::Book;

# the trick to hide this tests-only package was copied from
# https://github.com/davidolrik/DBIx-Class-FormTools

use 5.010;
use strict;
use warnings;

use base qw(DBIx::Class::Core);

use lib '.t/lib';

__PACKAGE__->table('books');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        size => 16,
        is_nullable => 0,
        is_auto_increment => 1,
    },
    title => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 0,
    },
    author => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 0,
    },
    pub_date => {
        data_type => 'date',
        is_nullable => 0,
    },
    num_pages => {
        data_type => 'integer',
        size => 16,
        is_nullable => 0,
    },
    isbn => {
        data_type => 'varchar',
        size => 32,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

1;

# vim: expandtab shiftwidth=4
