#!perl

use strict;
use warnings;

use Test::More tests => 39;
#use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    use_ok('Class::Meta::Declare');
}

{

    package Fake::ID;
    sub new { bless {}, shift }
    my $id = 1;
    sub id { $id++ }
}

my $declare;
{

    package MyApp::Thingy;
    use Class::Meta::Declare ':all';

    $declare = Class::Meta::Declare->new(
        meta       => [ key => 'thingy' ],
        attributes => [
            pi => {
                context => $CTXT_CLASS,
                authz   => $AUTHZ_READ,
                default => 3.1415927,
            },
            id => {
                authz   => $AUTHZ_READ,
                type    => $TYPE_INTEGER,
                default => sub { Fake::ID->new->id },
            },
            name => {
                required => 1,
                type     => $TYPE_STRING,
                default  => 'No Name Supplied',
            },
            age => { type => $TYPE_INTEGER, },
        ],
        methods => [
            some_method => {
                view => $VIEW_PUBLIC,
                code => sub {
                    my $self = shift;
                    return [ reverse @_ ];
                },
            }
        ]
    );
}

use Class::Meta::Declare qw(:type);
can_ok $declare, 'installed_types';
ok my @types = $declare->installed_types, '... and calling it should succeed';
is_deeply \@types, [
    qw/
      Class::Meta::Types::Numeric
      Class::Meta::Types::Perl
      Class::Meta::Types::String
      /
  ],
  '... and calling it should return the installed types';
ok $declare->installed_types('Class::Meta::Types::String'),
  '... and it should verify a given type';
ok !$declare->installed_types('Class::Meta::Types::Boolean'),
  '... and verify uninstalled types';

my $CLASS = 'MyApp::Thingy';
can_ok $CLASS=> 'new';
ok my $thing = $CLASS->new, '... and we should be able to create a new object';
isa_ok $thing, $CLASS, '... and the object it returns';

#
# Testing readonly attribute
#

can_ok $thing, 'id';
ok my $id = $thing->id, '... and fetching the id should succeed';
is $id, 1, '... and it should return a correct default value';
$thing->id('foo');  # XXX this silently fails.  Shouldn't it throw an exception?
is $thing->id, $id, '... and trying to reset the id should fail';
throws_ok { MyApp::Thingy->id }
  qr/\QCan't use string ("MyApp::Thingy") as a HASH ref/,
  '... but trying to call an instance method as a class method should fail';

#
# Testing a string attribute
#

can_ok $thing, 'name';
is $thing->name, 'No Name Supplied',
  '... and it should have the correct default value';
ok $thing->name('Ovid'), '... setting it should succeed';
is $thing->name, 'Ovid', '... and now it should return the correct value';

#
# Testing an integer attribute
#

can_ok $thing, 'age';
ok !defined $thing->age, '... and its initial value should be undefined';
throws_ok { $thing->age('Ovid') } qr/Value 'Ovid' is not a valid integer/,
  '... setting to a non-integer value should fail';

#
# Testing class methods
#

can_ok $CLASS, 'pi';
cmp_ok $CLASS->pi, 'eq', '3.1415927',
  'Class methods should return the correct value';
cmp_ok $thing->pi, 'eq', '3.1415927',
  '... even when called as instance methods';

#
# Testing added methods
#

can_ok $thing, 'some_method';
ok my $result = $thing->some_method(qw/foo bar/),
  '... and calling it should succeed';
is_deeply $result, [qw/bar foo/], '... and return the correct results';

#
# Testing metadata
#

can_ok $thing, 'my_class';
ok my $class = $thing->my_class, '... and calling it should succeed';
isa_ok $class, 'Class::Meta::Class', '... and the object it returns';

# constructors

my @constructors = sort map { $_->name } $class->constructors;
is_deeply \@constructors, ['new'],
  '... and it should return the correct constructors';

# attributes

my @attributes = sort map { $_->name } $class->attributes;
is_deeply \@attributes, [qw(age id name pi)], '... and the correct attributes';

# methods

my @methods = sort map { $_->name } $class->methods;
is_deeply \@methods, ['some_method'], '... and the correct methods';

{

    package Won't::Use::This;
    use Class::Meta::Declare ':all';

    Class::Meta::Declare->new(
        meta => [
            key     => 'thingy2',
            package => 'MyApp::Thingy2',
        ],
        attributes => [
            id => {
                authz   => $AUTHZ_READ,
                type    => $TYPE_INTEGER,
                default => sub { Fake::ID->new->id },
            },
            rank => {
                required => 1,
                type     => $TYPE_STRING,
                default  => 'private',
            },
            age => { type => $TYPE_INTEGER, },
        ],
        methods => [
            method => {
                view => $VIEW_PUBLIC,
                code => sub { return 'a method' },
            }
        ]
    );
}

my $CLASS2 = 'MyApp::Thingy2';
ok $CLASS2->can('new'), 'We should be able to override the default package';
ok !Won't::Use::This->can('new'),    # '
  '... and the package containing the declaration should not be altered';

ok my $thing2 = $CLASS2->new, 'Calling new() should succeed';
isa_ok $thing2, $CLASS2, '... and the object it returns';
is $thing2->rank, 'private', '... and we should be able to fetch instance data';
$thing2->rank('corporal');
is $thing2->rank, 'corporal',
  '... and generally have the class behave like it should';
