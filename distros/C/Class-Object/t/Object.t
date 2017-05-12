# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Foo.t'

use strict;
use lib qw(t/lib);
use Test::More tests => 10;

BEGIN { use_ok('Class::Object'); }

my $obj = Class::Object->new;
ok( defined $obj && $obj->isa('Class::Object'),         'Class::Object->new');

$obj->sub('foo', sub {
    my($self) = shift;
    $self->{foo} = $_[0] if @_;
    return $self->{foo};
});
ok( $obj->can('foo'),                             'sub() declares a method' );
$obj->foo(42);
is( $obj->foo, 42,                                '  they take arguments' );


my $another_obj = Class::Object->new;
isnt( ref $obj, ref $another_obj,       'Class::Object->new another object' );

ok( !$another_obj->can('foo'),                '  doesn\'t have any methods' );

$another_obj->sub('foo', sub {
    return 23
});
ok( $another_obj->can('foo'),        '  different version of the same meth' );
is( $another_obj->foo, 23,           '  works' );
is( $obj->foo,         42,           '  different from the first' );


my $clone = $obj->new;
$clone->foo(98);
is( $clone->foo, 98,                 'cloning' );
