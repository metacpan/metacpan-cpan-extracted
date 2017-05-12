use strict;
use Test::More tests => 2;

BEGIN { use_ok('Attribute::Unimplemented'); }

package SomeClass;

sub foo :Unimplemented {
    return 1;
}

package main;

my $warn;
$SIG{__WARN__} = sub { $warn = shift };

SomeClass->foo();
like($warn, qr/SomeClass::foo\(\) is not yet implemented/, 'warning');

1;
