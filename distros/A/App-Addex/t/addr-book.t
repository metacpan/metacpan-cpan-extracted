#!perl
use strict;
use warnings;

use Test::More tests => 2;

my $class = 'App::Addex::AddressBook';
use_ok($class);

eval { $class->entries };
like($@, qr/no behavior defined/, "exception thrown on virtual method");
