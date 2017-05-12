package Sample::Address;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

# Class and instance method

sub Table { "Addresses" }

# Class and instance method

sub Schema {
    return {
        Name => { TYPE => 'varchar', DEFAULT => 'Frank', },
        Phone => { TYPE => 'varchar', },
        EmployeeId => { REFERENCES => 'Sample::Employee', },
    }
}

package Sample::Employee;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub Table { "Employees" }

sub Schema {
    return {
      Name => { TYPE => 'varchar', },
      Dexterity => { TYPE => 'integer', },
    }
}

1;