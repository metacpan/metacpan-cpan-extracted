package Dancer2::Plugin::FormValidator::Role::Validator;

use Moo::Role;
use Types::Standard qw(ConsumerOf);
use namespace::clean;

has extension => (
    is        => 'ro',
    isa       => ConsumerOf['Dancer2::Plugin::FormValidator::Role::Extension'],
    predicate => 1,
);

requires 'validate';
requires 'message';

sub stop_on_fail {
    return 0;
}

1;
