package Catalyst::Plugin::PickComponents;

use strict;
use warnings;
use vars qw/$VERSION/;
$VERSION = '0.02';
use Module::Pluggable::Object;
use Catalyst::Utils ();
use MRO::Compat;

sub setup_components {
    my $class = shift;
    
    my $config  = $class->config->{ pick_components };

    unless ($config) {
        return $class->maybe::next::method(@_);
    }
    
    my @paths   = exists $config->{paths}   ? @{ delete $config->{paths} }   : ();
    my @modules = exists $config->{modules} ? @{ delete $config->{modules} } : ();
    my @expect_paths   = exists $config->{expect_paths}   ? @{ delete $config->{expect_paths} }   : ();
    my @expect_modules = exists $config->{expect_modules} ? @{ delete $config->{expect_modules} } : ();
    
    my (@plugins, @expect_plugins);
    if (scalar @paths) {
        my $locator = Module::Pluggable::Object->new(
            search_path => [ map { s/^(?=::)/$class/; $_; } @paths ],
            %$config
        );
        @plugins = $locator->plugins;
    }
    if (scalar @modules) {
        push @plugins, @modules;
    }
    if (scalar @expect_paths) {
        my $locator = Module::Pluggable::Object->new(
            search_path => [ map { s/^(?=::)/$class/; $_; } @expect_paths ],
        );
        @expect_plugins = $locator->plugins;
    }
    if (scalar @expect_modules) {
        push @expect_plugins, @expect_modules;
    }
    my %has = map { $_ => 1 } @plugins;
    $has{$_} = 0 foreach @expect_plugins;
    @plugins = grep { $has{$_} == 1 } keys %has;
    
    # below code is copied from Catalyst.pm sub setup_components
    
    my @comps = sort { length $a <=> length $b } @plugins;
    my %comps = map { $_ => 1 } @comps;
    
    for my $component ( @comps ) {

        # We pass ignore_loaded here so that overlay files for (e.g.)
        # Model::DBI::Schema sub-classes are loaded - if it's in @comps
        # we know M::P::O found a file on disk so this is safe

        Catalyst::Utils::ensure_class_loaded( $component, { ignore_loaded => 1 } );

        my $module  = $class->setup_component( $component );
        my %modules = (
            $component => $module,
            map {
                $_ => $class->setup_component( $_ )
            } grep { 
              not exists $comps{$_}
            } Devel::InnerPackage::list_packages( $component )
        );
        
        for my $key ( keys %modules ) {
            $class->components->{ $key } = $modules{ $key };
        }
    }
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::PickComponents - Pick up the components for Catalyst.

=head1 SYNOPSIS

    use Catalyst qw/
        PickComponents
    /;

    # configure which dir and modules to be loaded
    __PACKAGE__->config->{pick_components} = {
        paths => [ '::Controller', '::Model' ],
        modules => [ 'MyApp::View::TT' ],
        expect_paths => [ '::Controller::Admin', '::Controller::Search' ],
        expect_modules => [ 'MyApp::Controller::Admin', 'MyApp::Controller::Search' ],
    }
    
    # after ConfigLoader or something else, in YAML myapp.yml or myapp_local.yml
    pick_components:
      paths:
        - ::Controller
        - ::Model
      modules:
        - MyApp::View::TT
      expect_paths:
        - ::Controller::Admin
        - ::Controller::Search
      expect_modules:
        - MyApp::Controller::Admin
        - MyApp::Controller::Search

=head1 DESCRIPTION

This plugin gives you the rights to pick up what modules loaded for a certain application instance.

When source perl modules expand quickly, we might want to load different modules into different servers. For sure we can remove useless modules in different servers, but I'm afraid that it's hard to maintain and configure.

example:

    # http://www.myapp.com/, myapp_local.yml
    pick_components:
      paths:
        - ::Controller
        - ::Model
      modules:
        - MyApp::View::TT
      expect_paths:
        - ::Controller::Admin
        - ::Controller::Search
      expect_modules:
        - MyApp::Controller::Admin
        - MyApp::Controller::Search
    
    # http://search.myapp.com/, myapp_local.yml
    pick_components:
      paths:
        - ::Controller::Search
        - ::Model
      modules:
        - MyApp::View::TT
        - MyApp::Controller::Search
        - MyApp::Controller::Root
      expect_paths:
        - ::Controller::Admin
      expect_modules:
        - MyApp::Controller::Admin
    
    # http://admin.myapp.com/, myapp_local.yml
    pick_components:
      paths:
        - ::Controller::Admin
        - ::Model
      modules:
        - MyApp::View::TT
        - MyApp::Controller::Admin
        - MyApp::Controller::Root
      expect_paths:
        - ::Controller::Search
      expect_modules:
        - MyApp::Controller::Search

=head1 SEE ALSO

L<Catalyst::Runtime>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut