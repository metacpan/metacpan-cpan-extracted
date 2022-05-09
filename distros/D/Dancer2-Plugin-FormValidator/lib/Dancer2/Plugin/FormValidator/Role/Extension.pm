package Dancer2::Plugin::FormValidator::Role::Extension;

use strict;
use warnings;

use Moo::Role;
use Types::Standard qw(InstanceOf HashRef);
use namespace::clean;

has plugin => (
    is        => 'ro',
    isa       => InstanceOf['Dancer2::Plugin::FormValidator'],
    predicate => 1,
);

has config => (
    is  => 'ro',
    isa => HashRef,
    predicate => 1,
);

requires 'validators';

1;
