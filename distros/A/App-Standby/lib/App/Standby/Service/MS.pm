package App::Standby::Service::MS;
$App::Standby::Service::MS::VERSION = '0.04';
BEGIN {
  $App::Standby::Service::MS::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a Monitoring::Spooler service

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

=pod

=encoding utf-8

=head1 NAME

App::Standby::Service::MS - a Monitoring::Spooler service

=head1 NAME

App::Standby::Service::MS - a Monitoring::Spooler service

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
