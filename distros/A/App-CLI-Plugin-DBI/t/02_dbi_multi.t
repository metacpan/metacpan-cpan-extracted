use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyAppMulti;

our $DBI_OBJ1_ADDR;
our $DBI_OBJ2_ADDR;

{
	local *ARGV = [qw(main)];
	MyAppMulti->dispatch;
}

ok($DBI_OBJ1_ADDR != $DBI_OBJ2_ADDR);


