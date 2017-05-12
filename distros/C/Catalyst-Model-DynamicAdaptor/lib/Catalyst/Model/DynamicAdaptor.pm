package Catalyst::Model::DynamicAdaptor;

use strict;
use warnings;
use base qw/Catalyst::Model/;
use NEXT;
use Module::Recursive::Require;

our $VERSION = 0.02;

sub new {
    my $self  = shift->NEXT::new(@_);
    my $c     = shift;
    my $class = ref($self);

    my $base_class = $self->{class};
    my $config     = $self->{config} || {};
    my $mrr_args   = $self->{mrr_args} || {};

    my @plugins
        = Module::Recursive::Require->new($mrr_args)->require_of($base_class);

    no strict 'refs';
    for my $plugin (@plugins) {
        my %config = %{$config};
        my $obj ;
        if ( $plugin->can('new') ) {
            $obj = $plugin->new(\%config);
        }

        my $plugin_short = $plugin;
        $plugin_short =~ s/^$base_class\:\://g;
        my $classname = "${class}::$plugin_short";

        if ( $plugin->can('new') ) { 
            *{"${classname}::ACCEPT_CONTEXT"} = sub {
                return $obj;
            };
        }
        else {
            *{"${classname}::ACCEPT_CONTEXT"} = sub {
                return $plugin;
            };

        }
    }

    return $self;
}

1;

=head1 NAME

Catalyst::Model::DynamicAdaptor - Dynamically load adaptor modules

=head1 VERSION

0.01

=head1 SYNOPSIS

 package App::Web::Model::Logic;

 use base qw/Catalyst::Model::DynamicAdaptor/;

 __PACKAGE__->config(
    class => 'App::Logic', # all modules under App::Logic::* will be loaded
    # config => { foo => 'foo' , bar => 'bar' }, # constractor parameter for each loading module )
    # mrr_args => { path => '/foo/bar' } # Module::Recursive::Require parameter.
 );

 1;

 package App::Web::Controller::Foo;

 sub foo : Local {
    my ( $self, $c ) = @_;

    # same as App::Logic::Foo->new->foo(); if you have App::Logic::Foo::new
    # same as App::Logic::Foo->foo(); # if you do not have App::Logic::Foo::new
    $c->model('Logic::Foo')->foo() ; 
 }

 1;

=head1 DESCRIPTION

 Load modules dynamicaly like L<Catalyst::Model::DBIC::Schema> does.

=head1 MODULE

=head2 new

constructor

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=head1 THANKS

masaki

vkgtaro

hidek

hideden

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

