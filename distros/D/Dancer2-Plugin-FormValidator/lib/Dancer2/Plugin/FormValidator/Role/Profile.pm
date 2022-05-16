package Dancer2::Plugin::FormValidator::Role::Profile;

use strict;
use warnings;

use Moo::Role;

requires 'profile';

sub hook_before {
    my ($self, $profile, $input) = @_;

    return $profile;
}

1;
