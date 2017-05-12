package UserClass;
use strict;
use warnings;
use base qw( Catalyst::Authentication::Store::LDAP::User );

sub my_method {
    return 'frobnitz';
}

1;
