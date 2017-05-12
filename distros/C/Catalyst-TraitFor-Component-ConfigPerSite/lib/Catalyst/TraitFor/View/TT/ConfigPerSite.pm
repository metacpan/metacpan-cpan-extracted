package Catalyst::TraitFor::View::TT::ConfigPerSite;
use strict;
use warnings;

=head1 NAME

Catalyst::TraitFor::View::TT::ConfigPerSite - Extend Catalyst TT View to work with multiple sites at once

=head1 SYNOPSIS

    package MyApp::View::TT;

    use Moose;

    extends 'Catalyst::View::TT';

    with qw(Catalyst::TraitFor::View::TT::ConfigPerSite);

=head1 DESCRIPTION

This Role or Trait allows you to share an application between sites, clients, etc with different configuration for  databases. It extends Catalyst TT View to work with multiple template paths, per site or configuration.

=cut

use Moose::Role;
with qw( Catalyst::Component::InstancePerContext Catalyst::TraitFor::Component::ConfigPerSite);

use MRO::Compat;

use Data::Dumper;

=head1 METHODS

=head2 build_per_context_instance

=cut

sub build_per_context_instance {
    my ($self,$c,%args) = @_;
    return $_[0] unless ref($_[1]);

    my $config = $self->get_component_config($c);

    if (my $instance = $self->get_from_instance_cache($config)) {
	return $instance;
    }

    # Slightly evil - we use hash/array flattening side-effect in TT View constructor to inject/overwrite with site specific config
    foreach my $key ( keys %$config ) {
	next if ($key eq 'site_name');
	$args{$key} = $config->{$key};
    }

    my $new = $self->new($c, \%args);

    $self->put_in_instance_cache($config, $new);

    return $new;
}

=head1 SEE ALSO

Catalyst::Component::InstancePerContext

Moose::Role

=head1 AUTHOR

Aaron Trevena, E<lt>aaron@aarontrevena.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2013 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
