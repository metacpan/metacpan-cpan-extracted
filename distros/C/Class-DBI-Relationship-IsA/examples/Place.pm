package Place;

use base qw(Address::DBI);
__PACKAGE__->table('Place');
__PACKAGE__->columns(All => qw/placeid City/);

1;
