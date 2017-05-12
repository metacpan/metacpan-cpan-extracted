use strict;
use Test::More tests => 2;
use lib qw(t/lib);
use MyAppDefault;

our $DBI_DEFAULT_HANDLE;
our $DBI_OBJ1_ADDR;
our $DBI_OBJ2_ADDR;

{
	local *ARGV = [qw(main)];
	MyAppDefault->dispatch;
}

ok($DBI_DEFAULT_HANDLE eq "default");
ok($DBI_OBJ1_ADDR == $DBI_OBJ2_ADDR);
