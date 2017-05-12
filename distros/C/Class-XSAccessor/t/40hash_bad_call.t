use strict;
use warnings;

use Test::More tests => 19;

BEGIN { use_ok('Class::XSAccessor') };

package Hash;

use Class::XSAccessor {
    accessors   => [ qw(foo bar) ],
    constructor => 'new'
};

package main;

my $hash = Hash->new();

isa_ok $hash, 'Hash';
can_ok $hash, 'foo', 'bar';

$hash->foo('FOO');
$hash->bar('BAR');

is $hash->foo, 'FOO';
is $hash->bar, 'BAR';

my $ok;
my $err;

$ok = eval { Hash->foo; 1 };
$err = $@ || 'Zombie error';
ok(!$ok);
like $err, qr{Class::XSAccessor: invalid instance method invocant: no hash ref supplied };

$ok = eval { Hash->bar; 1 };
$err = $@ || 'Zombie error';
ok(!$ok);
like $err, qr{Class::XSAccessor: invalid instance method invocant: no hash ref supplied };

$ok = eval { Hash::foo() };
$err = $@ || 'Zombie error';
ok(!$ok);

# package name introduced in 5.10.1
SKIP: {
  skip "Old perl behaves funny. You should upgrade.", 1 if $] < 5.010001;
  like $err, qr{Usage: (Hash::)?foo\(self, \.\.\.\) };
}

$ok = eval { Hash::bar(); 1 };
$err = $@ || 'Zombie error';
ok(!$ok);

SKIP: {
  skip "Old perl behaves funny. You should upgrade.", 1 if $] < 5.010001;
  like $err, qr{Usage: (Hash::)?bar\(self, \.\.\.\) };
}

$ok = eval { Hash::foo( [] ); 1 };
$err = $@ || 'Zombie error';
ok(!$ok);
like $err, qr{Class::XSAccessor: invalid instance method invocant: no hash ref supplied };

$ok = eval { Hash::bar( '' ); 1 };
$err = $@ || 'Zombie error';
ok(!$ok);
like $err, qr{Class::XSAccessor: invalid instance method invocant: no hash ref supplied };

is Hash::foo($hash), 'FOO';
is Hash::bar($hash), 'BAR';
