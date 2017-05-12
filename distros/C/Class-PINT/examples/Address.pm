package Address;

use Place;
use base qw(Address::DBI);
Address->table('Address');
Address->column_types(array => qw/StreetAddress/);
Address->column_types(hash => qw/Dictionary/);
Address->columns(All => qw/addressid StreetNumber StreetAddress Town County Place/);
Address->is_a(Place=>'Place');

1;
