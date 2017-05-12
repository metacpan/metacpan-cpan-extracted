#!/usr/bin/perl

use strict;
use warnings;
no warnings 'redefine';

use Test::More tests => 43;
#use Test::More qw/no_plan/;

local $SIG{__WARN__} = sub {
    my $message = shift;
    return if $message =~ /Too late to run INIT block/;
    warn $message;
};

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => ( '../lib', 'test_lib' );
}

use Class::Trait;
{

    package Foo;
    sub new { bless {}, shift }
    sub name    { 'Foo' }
    sub explode { 'Foo explodes' }
}

my $foo = Foo->new;

#
# appling simple runtime traits to instances
#

require TSpouse;
can_ok 'TSpouse', 'apply';
ok +TSpouse->apply($foo),
  '... and applying the trait to an instance should succeed';
ok $foo->isa('Foo'), '... and the instance should still respect "isa"';
cmp_ok ref $foo, 'ne', 'Foo', '... but it should be blessed into a new class';
ok $foo->does('TSpouse'), '... and it should be able to do the new trait';
can_ok $foo, 'name';
is $foo->name, 'Foo', '... original methods should still be available';
can_ok $foo, 'explode';
is $foo->explode, 'Spouse explodes',
  '... but corresponding trait methods should override them';
can_ok $foo, 'fuse';
is $foo->fuse, 'Spouse fuse',
  '... and the new trait methods should be available';

my $foo2 = Foo->new;
is $foo2->explode, 'Foo explodes',
  'Different instances of classes should not share runtime traits';

#
# conflicting runtime traits to instances
#

can_ok 'Class::Trait', 'apply';
eval { Class::Trait->apply( $foo2, 'TSpouse', 'TBomb' ) };
ok $@,   'Trying to apply conflicting traits at runtime should fail';
like $@, qr/Package (?:\w|::)+ has conflicting methods \(.*\)/,
  '... with an appropriate error message';

undef $foo2;    # make sure we don't reuse it

# let's resolve those conflicts

$foo = Foo->new;
Class::Trait->apply(
    $foo,
    TSpouse => { exclude => 'fuse' },
    TBomb   => { exclude => 'explode' },
);
ok $foo->does('TSpouse'), '... and it should be able to do the first trait';
ok $foo->does('TBomb'),   '... and it should be able to do the second trait';
can_ok $foo, 'name';
is $foo->name, 'Foo', '... original methods should still be available';
can_ok $foo, 'explode';
is $foo->explode, 'Spouse explodes',
  '... but corresponding trait methods should override them';
can_ok $foo, 'fuse';
is $foo->fuse, 'Bomb fuse', '... and the new trait methods should be available';

$foo2 = Foo->new;
eval { Class::Trait->apply( $foo2, 'TSpouse' ) };
ok !$@,
  'We should be able to apply the conflicting traits to separate instances';

#
# let's apply the traits separately
#

$foo = Foo->new;
Class::Trait->apply( $foo, 'TSpouse' );
ok !$foo->does('TBomb'),
  'Trait information should not persist innappropriately';

Class::Trait->apply( $foo, 'TBomb' );
ok $foo->does('TBomb'), '... but we should have that info when it is available';
ok $foo->does('TSpouse'),
  '... and it should still report the other traits it can do';
can_ok $foo, 'name';
is $foo->name, 'Foo', '... original methods should still be available';
can_ok $foo, 'explode';
is $foo->explode, 'Bomb explodes',
  '... but later trait methods should override earlier ones';
can_ok $foo, 'fuse';
is $foo->fuse, 'Bomb fuse', '... and the new trait methods should be available';
my @does = sort $foo->does;

is_deeply \@does, [qw/TBomb TSpouse/],
    '... and it should be able to report all traits it can do';

#
# let's apply runtime composite traits with requirements
#

my $anon_package = ref $foo;
require Extra::TSpouse;

eval { Extra::TSpouse->apply($foo) };
ok $@,   'Trying to apply a runtime trait with unmet requirements should fail';
like $@, qr/Requirement \(alimony\) for Extra::TSpouse not in Foo::/,
  '... with an appropriate error message';

ok $foo->isa($anon_package),
  '... and the package of the object should not change';

{
    no warnings 'once';
    *Foo::alimony = sub { 'Foo alimony' };
}
eval { Extra::TSpouse->apply($foo) };
ok $@,   'Trying to apply a runtime trait with unmet requirements should fail';
like $@, qr/Requirement \(lawyer\) for Extra::TSpouse not in Foo::/,
  '... with an appropriate error message';
ok $foo->isa($anon_package),
  '... and the package of the object should not change';

{
    no warnings 'once';
    *Foo::lawyer = sub { 'Foo lawyer' };
}
ok +Extra::TSpouse->apply($foo),
  'Satisfying all requirements of runtime traits should succeed';
isnt ref $foo, $anon_package,
  '... and the instance should have a new anonymous package';
is $foo->explode, 'Extra spouse explodes',
  '... and the correct method should be overridden';
