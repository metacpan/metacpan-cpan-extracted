#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Role::NodeLoader 2.155;

# ABSTRACT: Load Node element in configuration tree

use Mouse::Role;
use strict;
use warnings;
use Carp;
use 5.10.0;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);

my $load_logger = get_logger("TreeLoad");

sub load_node {
    my ($self, %params) = @_ ;

    my $config_class_name = $params{config_class_name};
    my $config_class =  $self->config_model->get_model_clone($config_class_name) ;
    my $node_class = $config_class->{class} || 'Config::Model::Node';
    $load_logger->debug("Loading $config_class_name ". $self->location . " with $node_class");
    Mouse::Util::load_class($node_class);

    if (delete $params{check}) {
        carp "load_node; drop check param. Better let node query the instance";
    }
    $params{gist} //=  $config_class->{gist} if $config_class->{gist};
    return $node_class->new(%params) ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Role::NodeLoader - Load Node element in configuration tree

=head1 VERSION

version 2.155

=head1 SYNOPSIS

 $self->load_node( config_class_name => "...", %other_args);

=head1 DESCRIPTION

Role used to load a node element using L<Config::Model::Node> (default behavior).

If the config class overrides the default implementation, ( C<class> parameter ), the
override class is loaded and used to create the node.

=head1 METHODS

=head2 load_node

Creates a node object using all the named parameters passed to load_node. One of these
parameter must be C<config_class_name>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
