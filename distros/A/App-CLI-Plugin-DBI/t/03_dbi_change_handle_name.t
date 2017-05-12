use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyAppDefault;

our $RESULT;

{
	local *ARGV = [qw(changehandlename)];
	MyAppDefault->dispatch;
}

ok($RESULT eq "new_name");


