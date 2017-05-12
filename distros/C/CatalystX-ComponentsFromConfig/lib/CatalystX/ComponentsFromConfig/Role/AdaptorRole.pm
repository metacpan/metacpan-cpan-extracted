package CatalystX::ComponentsFromConfig::Role::AdaptorRole;
$CatalystX::ComponentsFromConfig::Role::AdaptorRole::VERSION = '1.006';
{
  $CatalystX::ComponentsFromConfig::Role::AdaptorRole::DIST = 'CatalystX-ComponentsFromConfig';
}
use MooseX::Role::Parameterized;
use Moose::Util::TypeConstraints;
use Moose::Util 'with_traits';
use MooseX::Types::Moose qw/ HashRef ArrayRef Str /;
use MooseX::Types::Common::String qw/LowerCaseSimpleStr/;
use MooseX::Types::LoadableClass qw/LoadableClass/;
use namespace::autoclean;

# ABSTRACT: parameterised role for trait-aware component adaptors


parameter component_type => (
    isa => LowerCaseSimpleStr,
    required => 1,
);

sub _format_args {
    my ($format, $args) = @_;

    return $format eq 'hashref' ? $args
        : $format eq 'list' ? %{$args}
        : die "Invalid args_format '$format'";
}

role {
    my $params = shift;
    my $type = ucfirst($params->component_type);


    has class => (
        isa => LoadableClass,
        is => 'ro',
        required => 1,
        coerce => 1,
    );


    has args => (
        isa => HashRef,
        is => 'ro',
        default => sub { {} },
    );


    has args_format => (
        isa => enum([qw(hashref list)]),
        is => 'ro',
        default => 'hashref',
    );


    has traits => (
        isa => ArrayRef[Str],
        is => 'ro',
    );

    around COMPONENT => sub {
        my ($orig, $class, $app, @rest) = @_;

        my $self = $class->$orig($app,@rest);
        my $other_class = $self->class;

        unless ($other_class->can('meta')) {
            Moose->init_meta(
                for_class => $other_class,
            );
        }

        if ($self->traits) {
            if (not $other_class->can('new_with_traits')) {
                my $new_class = with_traits(
                    $other_class,
                    'MooseX::Traits::Pluggable',
                );

                my $original_other_class = $other_class;
                $other_class = $new_class;

                $new_class->meta->add_method(
                    _trait_namespace => sub {
                        my ($other_self) = @_;
                        my $class = $original_other_class;

                        if ($class =~ s/^\Q$app//) {
                            my @list;
                            do {
                                push(@list, "${app}::TraitFor" . $class)
                            } while ($class =~ s/::\w+$// && $class);
                            push(@list, "${app}::TraitFor::${type}" . $class);
                            return \@list;
                        }
                        return $class . '::TraitFor';
                    },
                );
            }
            return $other_class->new_with_traits(_format_args $self->args_format, {
                traits => $self->traits,
                %{ $self->args },
            });
        }
        return $other_class->new(_format_args $self->args_format, $self->args);
    };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ComponentsFromConfig::Role::AdaptorRole - parameterised role for trait-aware component adaptors

=head1 VERSION

version 1.006

=head1 DESCRIPTION

Here we document implementation details, see
L<CatalystX::ComponentsFromConfig::ModelAdaptor> and
L<CatalystX::ComponentsFromConfig::ViewAdaptor> for usage examples.

This role uses L<MooseX::Traits::Pluggable> to allow you to add roles
to your model classes via the configuration.

=head1 ATTRIBUTES

=head2 C<class>

The name of the class to adapt.

=head2 C<args>

Hashref of arguments to pass to the constructor of the adapted class.

=head2 C<args_format>

String indicating how to pass the constructor arguments to the adapted
class. One of:

=over

=item C<hashref> (default)

Pass the arguments as a hash reference.

=item C<list>

Flatten the arugments into a key/value list.

=back

=head2 C<traits>

Arrayref of traits / roles to apply to the class we're adapting.

If set, and the L</class> has a C<new_with_traits> constructor, it
will be called with L</args> augmented by C<< traits => $traits >>. If
L</class> does not have that constructor, a subclass will be created
by applying L<MooseX::Traits::Pluggable> to L</class>, to get the
C<new_with_traits> constructor.

If L</class> provides C<new_with_traits>, that constructor is expected
to deal with converting whatever is in C<traits> into actual module
names. If, instead, we have to inject L<MooseX::Traits::Pluggable>, we
depend on its own name expansion, but we provide our own set of
namspaces: given a L</class> of
C<My::App::Special::Class::For::Things> loaded into the C<My::App>
Catalyst application, the following namespaces will be searched for
traits / roles:

=over 4

=item *

C<My::App::TraitFor::Special::Class::For::Things>

=item *

C<My::App::TraitFor::Class::For::Things>

=item *

C<My::App::TraitFor::For::Things>

=item *

C<My::App::TraitFor::Things>

=item *

C<My::App::TraitFor::${component_type}::Things>

=back

On the other hand, if the class name does not start with the
application name, just C<${class}::TraitFor> will be searched.

=head1 ROLE PARAMETERS

=head2 C<component_type>

The type of component to create, in lower case. Usually one of
C<'model'>, C<'view'> or C<'controller'>. There is no pre-packaged
adptor to create controllers, mostly because I could not think of a
sensible way to write it.

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
