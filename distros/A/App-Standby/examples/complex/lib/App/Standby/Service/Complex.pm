package App::Standby::Service::Complex;

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'App::Standby::Service::HTTP';
# has ...
# with ...
# initializers ...
sub _init_endpoints {
    my $self = shift;

    return $self->_config_values($self->name().'_endpoint');
}


# your code here ...

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

App::Standby::Service::Complex - Complex Service example

=cut
