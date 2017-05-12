package IO::All::Filesys;
use IO::All::Base;
extends 'IO::All::IO';

has name => ();
option overload => ();

sub upgrade {
    my $self = shift;
    $self->{name} = delete $self->{location}
        if $self->{location};
    $self->SUPER::upgrade(@_);
}

1;
