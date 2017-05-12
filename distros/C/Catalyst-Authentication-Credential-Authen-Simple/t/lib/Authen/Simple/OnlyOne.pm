package Authen::Simple::OnlyOne;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Params::Validate    qw[];

__PACKAGE__->options({
    pass => {
        type     => Params::Validate::SCALAR,
        optional => 0 
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    return ($password eq $self->pass);
}
1;

