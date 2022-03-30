package Dancer2::Plugin::FormValidator::Role::HasProfileMessages;

use Moo::Role;

with 'Dancer2::Plugin::FormValidator::Role::HasProfile',
    'Dancer2::Plugin::FormValidator::Role::HasMessages';

1;
