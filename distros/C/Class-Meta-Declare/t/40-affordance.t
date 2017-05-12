#!perl

use strict;
use warnings;

use Test::More tests => 37;
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
        meta => [
            key       => 'thingy',
            accessors => $ACC_AFFORDANCE,
        ],
        attributes => [
            pi => {
                context => $CTXT_CLASS,
                authz   => $AUTHZ_READ,
                default => 3.1415927,
                type    => $TYPE_SCALAR,
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

my $CLASS = 'MyApp::Thingy';
can_ok $CLASS=> 'new';
ok my $thing = $CLASS->new, '... and we should be able to create a new object';
isa_ok $thing, $CLASS, '... and the object it returns';

#
# Testing readonly attribute
#

can_ok $thing, 'get_id';
ok my $id = $thing->get_id, '... and fetching the id should succeed';
is $id, 1, '... and it should return a correct default value';

ok !$thing->can('set_id'),
  '... and no mutator should be created for read-only values';
throws_ok { MyApp::Thingy->get_id }
  qr/\QCan't use string ("MyApp::Thingy") as a HASH ref/,
  '... but trying to call an instance method as a class method should fail';

#
# Testing a string attribute
#

can_ok $thing, 'get_name';
is $thing->get_name, 'No Name Supplied',
  '... and it should have the correct default value';

can_ok $thing, 'set_name';
ok $thing->set_name('Ovid'), '... setting it should succeed';
is $thing->get_name, 'Ovid', '... and now it should return the correct value';

#
# Testing an integer attribute
#

can_ok $thing, 'get_age';
ok !defined $thing->get_age, '... and its initial value should be undefined';

can_ok $thing, 'set_age';
throws_ok { $thing->set_age('Ovid') } qr/Value 'Ovid' is not a valid integer/,
  '... setting to a non-integer value should fail';

#
# Testing class methods
#

can_ok $CLASS, 'get_pi';
cmp_ok $CLASS->get_pi, 'eq', '3.1415927',
  'Class methods should return the correct value';
cmp_ok $thing->get_pi, 'eq', '3.1415927',
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

    package Won't::Use::This;    # '
    use Class::Meta::Declare ':all';

    Class::Meta::Declare->new(
        meta => [
            key       => 'thingy2',
            package   => 'MyApp::Thingy2',
            accessors => $ACC_AFFORDANCE,
        ],
        attributes => [
            id => {
                authz   => $AUTHZ_READ,
                type    => $TYPE_INTEGER,
                default => sub { Fake::ID->new->id },
            },
            _rank => { default => 'private' },
            rank  => {
                required => 1,
                type     => $TYPE_STRING,
                code     => {
                    get => sub { shift->get__rank },
                    set => sub {
                        my $self = shift;
                        $self->set__rank(shift);

                        # incomplete list because this is just a test
                        if ( $self->get__rank =~ /^captain|colonelgeneral$/ ) {
                            $self->set_officer_on;
                        }
                        else {
                            $self->set_officer_off;
                        }
                        return $self;
                    },
                },
            },
            age     => { type => $TYPE_INTEGER, },
            officer => {
                type    => $TYPE_BOOLEAN,
                default => 0,
            },
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

is $thing2->get_rank, 'private', '... and we should be able to fetch instance data';

ok $thing2->can('set_rank'),
  'We should not need to redeclare our accessor type';
$thing2->set_rank('corporal');
is $thing2->get_rank, 'corporal',
  '... and generally have the class behave like it should';
