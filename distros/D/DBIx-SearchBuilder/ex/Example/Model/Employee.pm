package Example::Model::Employee;

use base qw/DBIx::SearchBuilder::Record/;

sub Table { "Employees" }

sub Schema {
    return {
      Name => { TYPE => 'varchar', },
      Dexterity => { TYPE => 'integer', },
    }
}

1;