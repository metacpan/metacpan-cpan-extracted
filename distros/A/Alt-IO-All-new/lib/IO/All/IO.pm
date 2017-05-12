package IO::All::IO;
use IO::All::Base;

has upgrade_methods => ( default => sub { [] } );

sub upgrade {
    my ($self) = @_;
    for my $key (keys %$self) {
        next if $key =~ /^_/;
        delete $self->{$key}
            unless $self->can($key);
    }
}

1;
