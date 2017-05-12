package My::db;

use DB2::db;

our @ISA = qw(DB2::db);

sub db_name { 'MYDB' }

sub setup_row_table_relationships
{
    my $self = shift;
    $self->add_table(
                     'Employee',
                    );
    $self->add_table(
                     'Product',
                    );
}

1;
