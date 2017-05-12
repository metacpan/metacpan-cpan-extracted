package Address::DBI;
use base qw(Class::PINT);
Address::DBI->connection('dbi:mysql:pint', 'root', '');

package Address;

use base qw(Address::DBI);
Address->table('Address');
Address->column_types(array => qw/StreetAddress/);
Address->column_types(boolean => qw/Flag/);
Address->column_types(hash => qw/Dictionary/);
Address->columns(All => qw/addressid StreetNumber StreetAddress Town City County Flag Dictionary/);

1;
