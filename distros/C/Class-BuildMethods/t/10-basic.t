#!perl 

#use Test::More qw/no_plan/;
use Test::More tests => 50;

my $CLASS = 'Class::BuildMethods';

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}
*refaddr = *Class::BuildMethods::_refaddr;

eval <<END_PACKAGE;
package Bad::Method;
use Class::BuildMethods '%bad method name%';
END_PACKAGE
ok $@,   'Trying to add illegal method names should fail';
like $@, qr/\Q'%bad method name%' is not a valid method name\E/,
  '... with an appropriate error message';
$CLASS->reclaim('Bad::Method');

{

    package Foo;
    use Class::BuildMethods qw(name rank);
}

my $foo = bless {}, 'Foo';
can_ok $foo, 'name';
ok !defined $foo->name, '... and its default value should be undefined';
ok $foo->name('Ovid'), '... and we should be able to set the name';
is $foo->name, 'Ovid', '... and later retrieve it';

$foo = bless [], 'Foo';
can_ok $foo, 'rank';
ok !defined $foo->rank, '... and its default value should be undefined';
ok $foo->rank('private'), '... and we should be able to set the rank';
is $foo->rank, 'private', '... and later retrieve it';

can_ok $CLASS, 'destroy';
$CLASS->destroy($foo);
ok !defined $foo->name, '... and it should remove instance data';
ok !defined $foo->rank, '... and it should remove instance data';

{

    package Foo::Bar;
    use Class::BuildMethods 
      poet       => { default => 'Publius Ovidius' },
      published  => { default => 0 };
}
my $foo_bar = bless \do { my $anon_scalar }, 'Foo::Bar';
can_ok $foo_bar, 'poet';
is $foo_bar->poet, 'Publius Ovidius',
  '... and we should be able to set default values';
ok $foo_bar->poet("John Davidson"),
  '... and we should be able to set a new value';
is $foo_bar->poet, 'John Davidson', '... and fetch the default value';
is $foo_bar->published, '0',
   '... and false defaults should be allowed';

{

    package Drinking::Customer;
    use Class::BuildMethods age => {
        validate => sub { shift; die "Too young" unless $_[0] >= 21 }
    };
}

my $customer = bless [], 'Drinking::Customer';
can_ok $customer, 'age';
eval { $customer->age(19) };
ok $@, '... and we should be able to provide validation';
like $@, qr/Too young/, '... and have any sort of error message we want';
ok $customer->age(21), '... but we should be able to set the values';
is $customer->age, 21, '... and later retrieve them';

my $cust2 = bless {}, 'Drinking::Customer';
ok $cust2->age(36),
  'We should be able to set the value on a different instance';
is $customer->age, 21, '... and have the previous instance unaffected';

eval <<"END_PACKAGE";
package Bogus::Package;
use Class::BuildMethods name => { no_such_key => 1 };
END_PACKAGE
ok $@,   'Trying to use unknown constraint for methods should fail';
like $@, qr/\QUnknown constraint keys (no_such_key) for Bogus::Package::name/,
  '... with an appropriate error message';

can_ok $CLASS, 'reset';
ok !$CLASS->reset('drinking::cstomer'),
  '... and calling it with an unknown package should return false';

ok $CLASS->reset('Drinking::Customer'),
  '... and calling it with an known package should return true';
ok !defined $customer->age,
  '... and the values for the methods should be undefined';

{

    package Foo::Bar;
    main::ok $CLASS->reset,
      '... and calling it without an argument should use the current package';
}
is $foo_bar->poet, 'Publius Ovidius',
  '... and default values should be restored after a reset';

can_ok $CLASS, 'build';
{

    package RunTime;
    $CLASS->build( 'name', rank => { default => 'private' } );
}
my $runtime = bless [], 'RunTime';
can_ok $runtime, 'name';
can_ok $runtime, 'rank';
is $runtime->rank, 'private',
  '... and methods added at runtime should work correctly';

can_ok $CLASS, 'dump';
my $dump     = $CLASS->dump($runtime);
my %expected = (
    rank => 'private',
    name => undef
);
is_deeply $dump, \%expected, '... and it should return a dump of the values';

can_ok $CLASS, 'packages';
ok my @packages = $CLASS->packages, '... and calling it should succeed';
my @expected
  = qw( Bogus::Package Check::Destroy Check::NoDestroy Drinking::Customer Foo Foo::Bar RunTime );
is_deeply \@packages, \@expected,
  '... and it should return the packages we have built methods for';

can_ok $CLASS, 'reclaim';
{

    package Foo::Bar;
    main::ok $CLASS->reclaim,
      '... and calling it without an argument should use the current package';
}
ok !defined $foo_bar->poet,
  '... and default values should not be restored after a reclaim';

@expected
  = qw( Bogus::Package Check::Destroy Check::NoDestroy Drinking::Customer Foo RunTime );
is_deeply [ $CLASS->packages ], \@expected,
  '... and packages() should not longer report the reclaimed package';

my $destroyed;
{

    package Check::Destroy;
    use Class::BuildMethods qw/name rank/;

    my $thing = bless [], 'Check::Destroy';
    $destroyed = ::refaddr($thing);
    $thing->name('bob')->rank('odor');
    main::is(
        Class::BuildMethods->_peek( 'Check::Destroy', 'name', $destroyed ),
        'bob', 'Internal values of data should be correct'
    );
}

ok !
  defined Class::BuildMethods->_peek( 'Check::Destroy', 'name', $destroyed ),
  '... but they should automatically be reclaimed when DESTROY is reached';

{

    package Check::NoDestroy;
    use Class::BuildMethods qw/name rank [NO_DESTROY]/;

    my $thing = bless [], 'Check::NoDestroy';
    $destroyed = ::refaddr($thing);
    $thing->name('bob')->rank('odor');
    main::is(
        Class::BuildMethods->_peek( 'Check::NoDestroy', 'name', $destroyed ),
        'bob',
        'Internal values of data should be correct'
    );
}

is +Class::BuildMethods->_peek( 'Check::NoDestroy', 'name', $destroyed ),
  'bob',
  '... even if the object is out of scope and [NO_DESTROY] has been specified';
