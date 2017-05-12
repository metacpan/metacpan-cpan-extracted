use Test::More tests => 1;

use lib qw(t/lib);

use DBIx::Class::BitField;

ok(my $row = DBIx::Class::BitField);

# TODO
