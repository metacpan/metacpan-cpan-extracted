#!perl
use strict;
use Test::More;

unless (eval {require Sub::Name}) {
    plan skip_all => "Sub::Name is not installed";
    exit 0;
}

plan tests => 6;

require_ok("Class::Accessor");
require_ok("Class::Accessor::Fast");

package Foo;
our @ISA = qw(Class::Accessor);
sub get {
    my ($self, $key) = @_;
    my @c = caller(1);
    main::is $c[3], "Foo::$key", "correct name for Foo sub $key";
    return $self->SUPER::get($key);
}
__PACKAGE__->mk_accessors(qw( foo ));

package Tricky;
require Tie::Hash;
our @ISA = qw(Tie::StdHash);
sub FETCH {
    my ($self, $key) = @_;
    my @c = caller(1);
    main::is $c[3], "Bar::$key", "correct name for Bar sub $key";
    return $self->SUPER::FETCH($key);
}
package Bar;
our @ISA = qw(Class::Accessor::Fast);
sub new {
    my ($class, $init) = @_;
    my %store;
    tie %store, "Tricky";
    %store = %$init;
    bless \%store, $class;
}
__PACKAGE__->mk_accessors(qw( bar ));

package main;
my $foo = Foo->new({ foo => 12345 });
is $foo->foo, 12345, "get initial foo";
my $bar = Bar->new({ bar => 54321 });
is $bar->bar, 54321, "get initial bar";
