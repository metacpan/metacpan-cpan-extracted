package CatalystX::ComponentsFromConfig::Role::PluginRole;
$CatalystX::ComponentsFromConfig::Role::PluginRole::VERSION = '1.006';
{
  $CatalystX::ComponentsFromConfig::Role::PluginRole::DIST = 'CatalystX-ComponentsFromConfig';
}
use MooseX::Role::Parameterized;
use MooseX::Types::Moose qw/Bool/;
use MooseX::Types::Common::String qw/LowerCaseSimpleStr/;
use CatalystX::InjectComponent;
use namespace::autoclean;

# ABSTRACT: parameterised role for plugins to create components from configuration


parameter component_type => (
    isa => LowerCaseSimpleStr,
    required => 1,
);


parameter skip_mvc_renaming => (
    isa => Bool,
    default => 0,
);


role {
    my $params = shift;
    my $type = $params->component_type;
    my $uctype = ucfirst($params->component_type);

    after 'setup_components' => sub {
        my $method = "_setup_dynamic_$type";
        shift->$method(@_);
    };

    method "_setup_dynamic_$type" => sub {
        my ($app) = @_;

        my $plugin_config = $app->config->{"${type}s_from_config"} || {};

        my $prefix = "${uctype}::";

        my $base_class = $plugin_config->{base_class} ||
            "CatalystX::ComponentsFromConfig::${uctype}Adaptor";

        my $config = $app->config || {};

        foreach my $comp_name ( grep { /^\Q$prefix\E/ } keys %$config ) {
            unless ($app->component($comp_name)) {
                my $local_base_class =
                    $config->{$comp_name}{base_class} || $base_class;
                CatalystX::InjectComponent->inject(
                    skip_mvc_renaming => $params->skip_mvc_renaming,
                    into => $app,
                    component => $local_base_class,
                    as => $comp_name,
                );
            }
        }
    };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ComponentsFromConfig::Role::PluginRole - parameterised role for plugins to create components from configuration

=head1 VERSION

version 1.006

=head1 DESCRIPTION

Here we document implementation details, see
L<CatalystX::ComponentsFromConfig::ModelPlugin> and
L<CatalystX::ComponentsFromConfig::ViewPlugin> for usage examples.

=head1 METHODS

=head2 C<setup_components>

C<after> the normal Catalyst components setup, call
C<_setup_dynamic_${component_type}>.

=head2 C<_setup_dynamic_${component_type}>

Loops through C<< $app->config >>, looking for sections that don't
correspond to existing components. For each one, uses
L<CatalystX::InjectComponent> to create the component, using as base
class either the one set globally in the C<<
${component_type}_from_config >> section (key C<base_class>), or the
one set locally in the C<base_class> value. If neither is set, the
default C<< CatalystX::ComponentsFromConfig::${component_type}Adaptor
>> is used.

=head1 ROLE PARAMETERS

=head2 C<component_type>

The type of component to create, in lower case. Usually one of
C<'model'>, C<'view'> or C<'controller'>. There is no pre-packaged
plugin to create controllers, mostly because I could not think of a
sensible adaptor for them.

=head2 C<skip_mvc_renaming>

By default L<CatalystX::InjectComponent> renames components that don't
start with one of C<Model::>, C<View::> or C<Controller::> according
to which corresponding L<Catalyst> component base class they inherit
from.  To avoid this (for example if your component is not a model,
view or controller), set this to true.

=head1 METHODS

=head1 AUTHORS

=over 4

=item *

Tomas Doran (t0m) <bobtfish@bobtfish.net>

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
