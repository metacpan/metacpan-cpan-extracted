package Address;

use Place;
warn "aa";
use base qw(Address::DBI);
warn "bb";
Address->table('Address');
warn "cc";
Address->columns(All => qw/addressid StreetNumber StreetAddress Town County Place/);
warn "dd";
Address->is_a(Place=>'Place');
warn "ee";
1;
