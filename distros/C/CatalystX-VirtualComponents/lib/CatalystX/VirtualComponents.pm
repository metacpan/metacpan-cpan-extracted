package CatalystX::VirtualComponents;
use Moose::Role;
use namespace::clean -except => qw(meta);
use Module::Pluggable::Object;
use Devel::InheritNamespace;

our $VERSION = '0.00004';

sub search_components {
    my ($class, $namespace, @namespaces) = @_;

    my @paths   = 
        map { ("${_}Base", $_) }
        qw( ::Controller ::C ::Model ::M ::View ::V )
    ;
    my $config  = $class->config->{ setup_components };
    my $extra   = delete $config->{ search_extra } || [];

    my $comps;
    foreach my $ns (@namespaces) {
        foreach my $path (@paths) {
            my $local_namespace = ($path =~ /^(.+)Base$/) ?
                "$namespace$1" : "$namespace$path"
            ;
            my $inherit_namespace = $path;
            $inherit_namespace =~ s/^(?=::)/$ns/;
            my @search_path = ($inherit_namespace, @$extra);

            my $loaded_comps = 
                Devel::InheritNamespace->new(
                    search_options => $config
                )->all_modules( $local_namespace, @search_path )
            ;
            while (my ($comp_class, $data) = each %$loaded_comps) {
                if ($comp_class =~ /::SUPER$/) {
                    next;
                }
                $comps->{$comp_class} = $data;
            }
        }
    }

    return $comps;
}

override setup_components => sub {
    my $class = shift;

    my @hierarchy;
    if (exists $class->config->{VirtualComponents}) {
        if (exists $class->config->{VirtualComponents}->{inherit}) {
            @hierarchy = (
                $class,
                @{ $class->config->{VirtualComponents}->{inherit} }
            );
        }
    } else {
        @hierarchy =
            grep { $_->isa('Catalyst') && $_ ne 'Catalyst' }
            $class->meta->linearized_isa
        ;
    }

    my $comps = $class->search_components( @hierarchy );

    foreach my $comp_class (keys %$comps) {
        my $module = $class->setup_component($comp_class);
        my %modules = (
            $comp_class => $module,
            map {
                $_ => $class->setup_component($_)
            } grep {
                not exists $comps->{$_}
            } Devel::InnerPackage::list_packages( $comp_class )
        );
        for my $key ( keys %modules ) {
            $class->components->{ $key } = $modules{ $key };
        }
    }

    if ($class->debug) {
        my $column_width = Catalyst::Utils::term_width() - 6;
        my $t = Text::SimpleTable->new($column_width);

        my @virtual_components = grep { $comps->{$_}->{is_virtual} } keys %$comps;

        $t->row($_) for sort @virtual_components;
        $class->log->debug( "Dynamically generated components:\n" . $t->draw . "\n" );
    }

};

1;

__END__

=head1 NAME

CatalystX::VirtualComponents - Setup Virtual Catalyst Components Based On A Parent Application Class

=head1 SYNOPSIS

    # in your base app...
    package MyApp;
    use Catalyst;

    # in another app...
    package MyApp::Extended;
    use Moose;
    use Catalyst qw(+CatalystX::VirtualComponents);
    
    extends 'MyApp';

=head1 DESCRIPTION

WARNING: YMMV with this module.

This module provides a way to reuse controllers, models, and views from 
another Catalyst application.

=head1 HOW IT WORKS

Suppose you have a Catalyst application with the following components:

    # Application MyApp::Base
    MyApp::Base::Controller::Root
    MyApp::Base::Model::DBIC
    MyApp::Base::View::TT

And then in MyApp::Extended, you wanted to reuse these components -- except 
you want to customize the Root controller, and you want to add another model 
(say, Model::XML::Feed).

In your new app, you can skip creating MyApp::Extended::Model::DBIC and
MyApp::Extended::View::TT -- CatalystX::VirtualComponents will take care of
these.

Just provide the customized Root controller and the new model:

    package MyApp::Extended::Controller::Root;
    use Moose;

    BEGIN { extends 'MyApp::Base::Controller::Root' }

    sub new_action :Path('new_action') {
        ....
    }

(We will skip XML::Feed, as it's just a regular model)

Then, in MyApp::Extended

    packge MyApp::Extended;
    use Moose;
    use Catalyst;

    extends 'MyApp::Base';

Note that MyApp::Extended I<inherits> from MyApp::Base. Naturally, if you
are inheriting from an application, you'd probably want to inherit all of
its controllers and such. To do this, specify CatalystX::VirtualComponents
in the Catalyst plugin list for MyApp::Extended:

    __PACKAGE__->setup( qw(
        ... # your regular Catalyst plugins
        +CatalystX::VirtualComponent
    ) );

When setup() is run, CatalystX::VirtualComponent will intercept the component
setup code and will automatically create I<virtual> subclasses for components
that exist in MyApp::Base, but I<not> in MyApp::Extended. In the above case,
MyApp::Extended::View::TT and MyApp::Extended::Model::DBIC will be created.

MyApp::Extended::Controller::Root takes precedence over the base class, so
only the local component will be loaded.  MyApp::Extended::Model::XML::Feed
only exists in the MyApp::Extended namespace, so it just works like a
normal Catalyst model.

=head1 GENERATING VIRTUAL CLASSES WITHOUT INHERITANCE

If you don't want to subclass, or use a more fine-grained control on which
namespaces to look for base components, specify the namespaces in a config
element:

    __PACKAGE__->config(
        VirtualComponents => {
            inherit => [
                'NamespaceA',
                'NamespaceB'
            ]
        }
    );

=head1 USING IN CONJUNCTION WITH CatalystX::AppBuilder

Simply add CatalystX::VirtualComponents in the plugin list:

    package MyApp::Extended::Builder;
    use Moose;

    extends 'CatalystX::AppBuilder';

    override _build_plugins {
        my $plugins = super();
        push @$plugins, '+CatalystX::VirtualComponents';
        return $plugins;
    };

    1;

=head1 METHODS

=head2 search_components($class)

Finds the list of components for Catalyst app $class.

=head2 setup_components()

Overrides Catalyst's setup_components() method.

=head1 TODO

Documentation. Samples. Tests.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut