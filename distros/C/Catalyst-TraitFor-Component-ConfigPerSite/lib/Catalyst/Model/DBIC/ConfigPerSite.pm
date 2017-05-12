package Catalyst::Model::DBIC::ConfigPerSite;
use strict;

=head1 NAME

Catalyst::Model::DBIC::ConfigPerSite - superclass for DBIC::Schema models

=head1 DESCRIPTION

Provides per-site database connections in your DBIC::Schema model

=head1 SYNOPSIS

package MyApp::Model::DBIC;

use Moose;

extends 'Catalyst::Model::DBIC::ConfigPerSite';

...

=cut

use Data::Dumper;
use Moose;

extends 'Catalyst::Model::DBIC::Schema';

with qw( Catalyst::Component::InstancePerContext Catalyst::TraitFor::Component::ConfigPerSite);

has '+schema_class' => (
    required => 0
);

=head1 METHODS

=head2 build_per_context_instance

=cut

sub build_per_context_instance {
    my ($self, $c) = @_;
    return $self unless blessed($c);
    my $config = $self->get_component_config($c);

    if (my $instance = $self->get_from_instance_cache($config)) {
	return $instance;
    }

    my @connect_info = ( @{$config->{connect_info}}{qw/dsn user password/});

    my $new = bless({ %$self }, ref($self));
    my $schema = $new->schema->clone;
    $new->config($config);

    $new->schema($self->schema->connect(@connect_info));

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

 This library is free software; you can redistribute it and/or
 it under the same terms as Perl itself, either Perl version 5
 at your option, any later version of Perl 5 you may have avai

=cut

1;
