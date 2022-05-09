use strict;
use warnings;

package Validator {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Profile';

    has profile_hash => (
        is       => 'ro',
        required => 1,
    );

    sub profile {
        return $_[0]->profile_hash;
    }
}

1;
