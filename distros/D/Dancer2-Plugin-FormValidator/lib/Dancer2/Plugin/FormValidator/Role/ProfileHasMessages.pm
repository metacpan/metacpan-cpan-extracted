package Dancer2::Plugin::FormValidator::Role::ProfileHasMessages;

use Moo::Role;

with 'Dancer2::Plugin::FormValidator::Role::Profile',
    'Dancer2::Plugin::FormValidator::Role::HasMessages';

1;
