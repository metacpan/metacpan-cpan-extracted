use strict;
use lib qw(t/lib);

use Test::More tests => 1;
use Music::DBI;

my @database = Music::DBI->databases;

SKIP: {
	skip (Music::DBI->skip_message, 1) unless(Music::DBI->has_databases);


eval q| require Music::NotSub |;

like($@, qr/can be used only by Class::DBI and its subclass/);


}
