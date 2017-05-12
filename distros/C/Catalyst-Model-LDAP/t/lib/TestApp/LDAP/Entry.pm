package TestApp::LDAP::Entry;

use strict;
use warnings;
use base qw/Catalyst::Model::LDAP::Entry/;

sub is_cool {
    my ($self) = @_;

    return $self->uid . ' is cool!';
}

1;
