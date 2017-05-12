
use Test::More tests => 3;

BEGIN { use_ok('Business::BR::Ids::Common', '_dot_10') };

{
my @a = (1,1,1,1);
my @b = (1,1,1,1);

is(_dot_10(\@a, \@b), 4, "_dot_10 works");
}

{
my @a = (1,2,3,3);
my @b = (2,5,2,6);

is(_dot_10(\@a, \@b), 18, "_dot_10 works");
}
