package CatalystX::InjectComponent;
{
  $CatalystX::InjectComponent::VERSION = '0.025';
}
# ABSTRACT: Inject components into your Catalyst application

use warnings;
use strict;


use Devel::InnerPackage;
use Class::Inspector;
use Carp;

sub put_package_into_INC ($) {
    my $package = shift;
    (my $file = "$package.pm") =~ s{::}{/}g;
    $INC{$file} ||= 1;
}

sub loaded ($) {
    my $package = shift;
    if ( Class::Inspector->loaded( $package ) ) {
        put_package_into_INC $package; # As a courtesy
        return 1;
    }
    return 0;
}

sub inject {
    my $self = shift;
    my %given = @_;

    my ($into, $component, $as);
    if ( $given{catalyst} ) { # Legacy argument parsing
        ($into, $component, $as) = @given{ qw/catalyst component into/ };
    }
    else {
        ($into, $component, $as) = @given{ qw/into component as/ };
    }
    
    croak "No Catalyst (package) given" unless $into;
    croak "No component (package) given" unless $component;

    unless ( loaded $component ) {
        eval "require $component;" or croak "Couldn't require (component base) $component: $@";
    }

    $as ||= $component;
    unless ( $as =~ m/^(?:Controller|Model|View)::/ || $given{skip_mvc_renaming} ) {
        my $category;
        for (qw/ Controller Model View /) {
            if ( $component->isa( "Catalyst::$_" ) ) {
                $category = $_;
                last;
            }
        }
        croak "Don't know what kind of component \"$component\" is" unless $category;
        $as = "${category}::$as";
    }
    my $component_package = join '::', $into, $as;

    unless ( loaded $component_package ) {
        eval "package $component_package; use parent qw/$component/; 1;" or
            croak "Unable to build component package for \"$component_package\": $@";
        put_package_into_INC $component_package; # As a courtesy
    }

    $self->_setup_component( $into => $component_package );
    for my $inner_component_package ( Devel::InnerPackage::list_packages( $component_package ) ) {
        $self->_setup_component( $into => $inner_component_package );
    }
}

sub _setup_component {
    my $self = shift;
    my $into = shift;
    my $component_package = shift;
    $into->components->{$component_package} = $into->setup_component( $component_package );
}

1; # End of CatalystX::InjectComponent

__END__
=pod

=head1 NAME

CatalystX::InjectComponent - Inject components into your Catalyst application

=head1 VERSION

version 0.025

=head1 SYNOPSIS

    package My::App;

    use Catalyst::Runtime '5.80';

    use Moose;
    BEGIN { extends qw/Catalyst/ }

    ...

    after 'setup_components' => sub {
        my $class = shift;
        CatalystX::InjectComponent->inject( into => $class, component => 'MyModel' );
        if ( $class->config->{ ... ) {
            CatalystX::InjectComponent->inject( into => $class, component => 'MyRootV2', as => 'Controller::Root' );
        }
        else {
            CatalystX::InjectComponent->inject( into => $class, component => 'MyRootV1', as => 'Root' ); # Controller:: will be automatically prefixed
        }
    };

=head1 DESCRIPTION

CatalystX::InjectComponent will inject Controller, Model, and View components into your Catalyst application at setup (run)time. It does this by creating
a new package on-the-fly, having that package extend the given component, and then having Catalyst setup the new component (via C<< ->setup_component >>)

=head1 So, how do I use this thing?

You should inject your components when appropriate, typically after C<setup_compenents> runs

If you're using the Moose version of Catalyst, then you can use the following technique:

    use Moose;
    BEGIN { extends qw/Catalyst/ }

    after 'setup_components' => sub {
        my $class = shift;

        CatalystX::InjectComponent->inject( into => $class, ... )
    };

=head1 METHODS

=head2 CatalystX::InjectComponent->inject( ... )

    into        The Catalyst package to inject into (e.g. My::App)
    component   The component package to inject
    as          An optional moniker to use as the package name for the derived component 

For example:

    ->inject( into => My::App, component => Other::App::Controller::Apple )
        
        The above will create 'My::App::Controller::Other::App::Controller::Apple'

    ->inject( into => My::App, component => Other::App::Controller::Apple, as => Apple )

        The above will create 'My::App::Controller::Apple'

=head1 ACKNOWLEDGEMENTS

Inspired by L<Catalyst::Plugin::AutoCRUD>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

