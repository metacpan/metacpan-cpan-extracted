package Config::Yak::LazyConfig;
{
  $Config::Yak::LazyConfig::VERSION = '0.23';
}
BEGIN {
  $Config::Yak::LazyConfig::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a role to provide a lazy initialized config attribute

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose::Role;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use Config::Yak;

# extends ...
# has ...
has 'config' => (
    'is'      => 'rw',
    'isa'     => 'Config::Yak',
    'lazy'    => 1,
    'builder' => '_init_config',
);

# with ...
# initializers ...
sub _init_config {
    my $self = shift;

    my $Config = Config::Yak::->new( { 'locations' => $self->_config_locations(), } );

    return $Config;
} ## end sub _init_config

# requires ...
requires '_config_locations';

# your code here ...

no Moose::Role;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Config::Yak::LazyConfig - a role to provide a lazy initialized config attribute

=head1 SYNOPSIS

    use Moose;
    with 'Config::Yak::LazyConfig';

=head1 DESCRIPTION

This Moose role provides an config attribute giving access to an
lazyly constructed Config::Yak instance.

=head1 NAME

Config::Yak::LazyConfig - This role provides an lazy config attribute.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
