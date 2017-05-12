use Test::More tests => 4;

BEGIN { use_ok('Class::Multimethods::Pure') }

package Foo;
package Bar;
package Baz;
our @ISA = ('Foo');
package main;

multi foo => Foo => sub { 'A' };
multi foo => Bar => sub { 'B' };

my $foo = bless {} => 'Foo';
my $bar = bless {} => 'Bar';
my $baz = bless {} => 'Baz';

is(foo($foo), 'A', 'SMD');
is(foo($bar), 'B', 'SMD');
is(foo($baz), 'A', 'SMD');

# vim: ft=perl :
