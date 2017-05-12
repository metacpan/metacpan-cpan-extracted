use warnings;
use strict;

use Test::More tests => 4;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

sub foo { }

sub munge_caller(@) { [ @_[0,1,2,10] ] }

sub caller_here() { munge_caller(caller(0)) }

my @attributes;
sub atthandler { push @attributes, [ @_[0..2], munge_caller(@{$_[3]}) ] }

use Attribute::Lexical "CODE:c0", \&atthandler;

sub foo :c0;    is_deeply $attributes[0], [\&foo,"c0",undef,caller_here()];
sub foo :c0(x); is_deeply $attributes[1], [\&foo,"c0","x",caller_here()];

sub bar() {
	sub foo :c0; is_deeply $attributes[2], [\&foo,"c0",undef,caller_here()];
	use Attribute::Lexical "CODE:c1", \&atthandler;
	sub foo :c0; is_deeply $attributes[3], [\&foo,"c0",undef,caller_here()];
}
bar();

1;
