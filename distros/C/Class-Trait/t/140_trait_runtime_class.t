#!/usr/bin/perl

use strict;
use warnings;
no warnings 'redefine';

#use Test::More tests => 33;
use Test::More qw/no_plan/;
use Class::Trait;

sub clean_inc {
    my @packages = qw(
      Circle
      Extra::TSpouse
      Foo
      Polygamy
      TBomb
      TDisallowed
      TSpouse
      TestTraits
    );

    foreach my $package (@packages) {
        no strict 'refs';
        clean_package( $package, keys %{"${package}::"} );
    }
    my @includes = map { s{::}{/}g; "$_.pm" } @packages;
    delete @INC{@includes};

    eval <<'    END_FOO';
        package Foo;
        sub new { bless {}, shift }
        sub name    { 'Foo' }
        sub explode { 'Foo explodes' }
    }
    END_FOO
}

sub clean_package {
    my ( $package, @globs ) = @_;
    no strict 'refs';
    foreach my $glob (@globs) {
        undef *{"${package}::$glob"};
    }
    Class::Trait::_clear_all_caches();
    Class::Trait::_clear_does_cache();    # internal testing hook
    no warnings 'once';
    undef $Foo::TRAITS;
}

local $SIG{__WARN__} = sub {
    my $message = shift;
    return if $message =~ /Too late to run INIT block/;
    warn $message;
};

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => ( '../lib', 'test_lib' );
}

#
# appling simple runtime traits to instances
#

clean_inc();
Class::Trait->apply(Foo => 'TSpouse');
my $foo = Foo->new;
isa_ok $foo, 'Foo', '... and the object it returns';
can_ok 'Foo', 'does';
ok +Foo->does('TSpouse'), '... and it should be able to do the new trait';
can_ok $foo, 'name';
is $foo->name, 'Foo', '... original methods should still be available';
can_ok $foo, 'explode';
is $foo->explode, 'Spouse explodes',
  '... but corresponding trait methods should override them';
can_ok $foo, 'fuse';
is $foo->fuse, 'Spouse fuse',
  '... and the new trait methods should be available';

my $foo2 = Foo->new;
is $foo2->explode, 'Spouse explodes',
  'Different instances of classes should share runtime traits applied to classes';

#
# conflicting runtime traits to instances
#

clean_inc();
can_ok 'Class::Trait', 'apply';
eval { Class::Trait->apply( 'Foo', 'TSpouse', 'TBomb' ) };
ok $@,   'Trying to apply conflicting traits at runtime should fail';
like $@, qr/Package (?:\w|::)+ has conflicting methods \(.*\)/,
  '... with an appropriate error message';


# let's resolve those conflicts

clean_inc();
Class::Trait->apply(
    'Foo',
    TSpouse => { exclude => 'fuse' },
    TBomb   => { exclude => 'explode' },
);
$foo = Foo->new;
ok $foo->does('TSpouse'), '... and it should be able to do the first trait';
ok $foo->does('TBomb'),   '... and it should be able to do the second trait';
can_ok $foo, 'name';
is $foo->name, 'Foo', '... original methods should still be available';
can_ok $foo, 'explode';
is $foo->explode, 'Spouse explodes',
  '... but corresponding trait methods should override them';
can_ok $foo, 'fuse';
is $foo->fuse, 'Bomb fuse', '... and the new trait methods should be available';


#
# let's apply the traits separately
#

clean_inc();
Class::Trait->apply( Foo => 'TSpouse' );
$foo = Foo->new;
ok !$foo->does('TBomb'),
  'Trait information should not persist innappropriately';

Class::Trait->apply( Foo => 'TBomb' );
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

clean_inc();
eval { Class::Trait->apply(Foo => 'Extra::TSpouse') };
ok $@,   'Trying to apply a runtime trait with unmet requirements should fail';
like $@, qr/Requirement \(alimony\) for Extra::TSpouse not in Foo/,
  '... with an appropriate error message';

clean_inc();
{
    no warnings 'once';
    *Foo::alimony = sub { 'Foo alimony' };
}
eval { Class::Trait->apply(Foo => 'Extra::TSpouse') };
ok $@,   'Trying to apply a runtime trait with unmet requirements should fail';
like $@, qr/Requirement \(lawyer\) for Extra::TSpouse not in Foo/,
  '... with an appropriate error message';

clean_inc();
{
    no warnings 'once';
    *Foo::alimony = sub { 'Foo alimony' };
    *Foo::lawyer = sub { 'Foo lawyer' };
}
ok +Class::Trait->apply(Foo => 'Extra::TSpouse'),
  'Satisfying all requirements of runtime traits should succeed';
is $foo->explode, 'Extra spouse explodes',
  '... and the correct method should be overridden';
