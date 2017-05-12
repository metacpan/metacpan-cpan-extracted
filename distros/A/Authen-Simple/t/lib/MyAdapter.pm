package MyAdapter;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

__PACKAGE__->options({
    credentials => {
        type     => Params::Validate::HASHREF,
        default  => { },
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    if ( exists $self->credentials->{$username} && $password eq $self->credentials->{$username} ) {

        $self->log->debug( qq/Successfully authenticated user '$username'./ )
          if $self->log;

        return 1;
    }

    $self->log->debug( qq/Failed to authenticate user '$username'. Reason: 'Invalid credentials'/ )
      if $self->log;

    return 0;
}

1;
