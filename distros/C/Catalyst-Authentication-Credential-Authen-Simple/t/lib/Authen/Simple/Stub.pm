package Authen::Simple::Stub;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

sub check {
    my ( $self, $username, $password ) = @_;

    return ($username eq $password);
}
1;

