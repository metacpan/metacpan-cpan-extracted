package Example::Model::Address;

use base qw/DBIx::SearchBuilder::Record/;

# Class and instance method

sub Table { "Addresses" }

# Class and instance method

sub Schema {
    return {
        Name => { TYPE => 'varchar', },
        Phone => { TYPE => 'varchar', },
        EmployeeId => { REFERENCES => 'Example::Model::Employee', },
    }
}

1;