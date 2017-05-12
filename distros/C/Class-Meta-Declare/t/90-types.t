#!perl

use strict;
use warnings;

use Test::More tests => 8;
#use Test::More qw/no_plan/;
use Test::Exception;

my $DECLARE;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    $DECLARE = 'Class::Meta::Declare';
    use_ok $DECLARE, ":all" or die;
}

eval {
    $DECLARE->new(
        meta => [
            key     => 'has_many',
            package => 'Foo',
        ],
        attributes => [
            some_object => {
                type => 'faux',
            },
        ]
    );
};
my $err = $@;
ok $err,   'Using a non-standard type should fail';
like $err, qr/\ACould not find type class for faux at/,
  '... with an appropriate error message';

{

    package Faux::Type;
    $DECLARE->new(
        meta => [
            key => 'faux',
        ]
    );
}

# Class::Meta::Declare will try to use this class unless it's already used.
$INC{'Faux/Type.pm'} = 1;
eval {
    $DECLARE->new(
        meta => [
            key     => 'has_many',
            package => 'Bar',
        ],
        attributes => [
            some_object => {
                type => 'faux',
            },
        ]
    );
};
$err = $@;
ok !$err, 'Loading a non-standard type should succeed if the class is loaded';
ok my $f = Bar->new, '... and we should be able to create a new object';

eval { $f->some_object(3) };
ok $err = $@,
  'Setting the non-standard type attribute to the wrong type should fail';
like $err, qr/\AValue '3' is not a valid Faux::Type/,
  '... with an appropriate error message';

eval { $f->some_object(Faux::Type->new) };
ok !$@,
  '... but setting it to a valid type should succeed';
