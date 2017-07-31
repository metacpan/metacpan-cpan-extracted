package Clustericious::RouteBuilder;

use strict;
use warnings;
use 5.010;
use Clustericious::App;
use Log::Log4perl qw( :easy );
use Mojo::Util qw( monkey_patch );

# ABSTRACT: Route builder for Clustericious applications
our $VERSION = '1.26'; # VERSION


my %routes;

# Much of the code below taken directly from Mojolicious::Lite.
sub import {
  my($class, $app_class) = @_;
  my $caller = caller;
    
  unless($app_class)
  {
    if ($caller->isa("Clustericious::App"))
    {
      $app_class = $caller;
    }
    else
    {
      $app_class = $caller;
      $app_class =~ s/::Routes$// or die "could not guess app class : ";
    }
  }

  my @routes;
  $routes{$app_class} = \@routes;

  # Route generator
  my $route_sub = sub
  {
    my ($methods, @args) = @_;

    my ($cb, $constraints, $defaults, $name, $pattern);
    my $conditions = [];

    # Route information
    my $condition;
    while (my $arg = shift @args)
    {

      # Condition can be everything
      if ($condition)
      {
        push @$conditions, $condition => $arg;
                $condition = undef;
      }

      # First scalar is the pattern
      elsif (!ref $arg && !$pattern)
      {
        $pattern = $arg;
      }

      # Scalar
      elsif (!ref $arg && @args)
      {
        $condition = $arg;
      }

      # Last scalar is the route name
      elsif (!ref $arg)
      {
        $name = $arg;
      }

      # Callback
      elsif (ref $arg eq 'CODE')
      {
        $cb = $arg;
      }

      # Constraints
      elsif (ref $arg eq 'ARRAY')
      {
        $constraints = $arg;
      }

      # Defaults
      elsif (ref $arg eq 'HASH')
      {
        $defaults = $arg;
      }
    }

    # Defaults
    $cb ||= sub {1};
    $constraints ||= [];

    # Merge
    $defaults ||= {};
    $defaults = {%$defaults, cb => $cb};

    # Name
    $name ||= '';

    push @routes, {
      name        => $name,
      pattern     => $pattern,
      constraints => $constraints,
      conditions  => $conditions,
      defaults    => $defaults,
      methods     => $methods
    };

  };

  # Export
  monkey_patch $app_class, startup_route_builder => \&_startup_route_builder;

  monkey_patch $caller, any => sub { $route_sub->(ref $_[0] ? shift : [], @_) };
  monkey_patch $caller, $_  => sub { unshift @_, 'delete'; goto $route_sub } for qw( Delete del );

  foreach my $method (qw( get head ladder post put websocket authenticate authorize ))
  {
    monkey_patch $caller, $method => sub { unshift @_, $method; goto $route_sub };
  }
}

sub _startup_route_builder {
  my($app, $auth_plugin) = @_;

  my $stashed = $routes{ ref $app } // do { WARN "no routes stashed for $app"; [] };
  my @stashed            = @$stashed;
  my $routes             = $app->routes;
  my $head_route         = $app->routes;
  my $head_authenticated = $head_route;

  for my $spec (@stashed)
  {
    my      ($name,$pattern,$constraints,$conditions,$defaults,$methods) =
    @$spec{qw/name  pattern  constraints  conditions  defaults  methods/};

    # authenticate, always connects to app->routes
    if (!ref $methods && $methods eq 'authenticate')
    {
      my $realm = $pattern || ref $app;
      my $cb = defined $auth_plugin ? sub { $auth_plugin->authenticate(shift, $realm) } : sub { 1 };
      $head_route = $head_authenticated = $routes =
      $app->routes->under->to( { cb => $cb } )->name("authenticated");
      next;
    }

    # authorize replaces previous authorize's
    if (!ref $methods && $methods eq 'authorize')
    {
      die "put authenticate before authorize" unless $head_authenticated;
      my $action = $pattern;
      my $resource = $name;
      if($auth_plugin)
      {
        $head_route = $routes = $head_authenticated->under->to( {
          cb => sub {
            my($c) = @_;
            # Dynamically compute resource/action
            my ($d_resource,$d_action) = ($resource, $action);
            $d_resource =~ s/<path>/$c->req->url->path/e if $d_resource;
            $d_resource ||= $c->req->url->path;
            $d_action =~ s/<method>/$c->req->method/e if $d_action;
            $d_action ||= $c->req->method;
            $auth_plugin->authorize( $c, $d_action, $d_resource );
          } 
        });
      }
      else
      {
        $head_route = $routes = $head_authenticated->under->to({ cb => sub { 1 } });
      }
      next;
    }

    # ladders don't replace previous ladders
    if (!ref $methods && $methods eq 'ladder')
    {
      die "constraints not handled in ladders" if $constraints && @$constraints;
      $routes = $routes
        ->under( $pattern )
        ->over($conditions)
        ->to($defaults)
        ->name($name);
      next;
    }

    # WebSocket?
    my $websocket = 1 if !ref $methods && $methods eq 'websocket';
    $methods = [] if $websocket;

    # Create route
    my $route = $routes
      ->route( $pattern, @$constraints )
      ->over($conditions)
      ->via($methods)
      ->to($defaults)
      ->name($name);

    # WebSocket
    $route->websocket if $websocket;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::RouteBuilder - Route builder for Clustericious applications

=head1 VERSION

version 1.26

=head1 SYNOPSIS

 package MyApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 package MyApp::Routes;

 use Clustericious::RouteBuilder;
 
 get '/' => sub { shift->render(text => 'welcome to myapp') };

=head1 DESCRIPTION

This module provides a simplified interface for creating routes for your 
L<Clustericious> application.  To use it, create a Routes.pm that lives 
directly under your application's namespace (for example above MyApp's 
route module is MyApp::Routes).  The interface is reminiscent of 
L<Mojolicious::Lite>, because it was forked from there some time ago.

=head1 FUNCTIONS

=head2 any

Define an HTTP route that matches any HTTP command verb.

=head2 get

Define an HTTP GET route

=head2 head

Define an HTTP HEAD route

=head2 post

Define an HTTP POST route

=head2 put

Define an HTTP PUT route

=head2 del

Define an HTTP DELETE route.

=head2 websocket

Define a Websocket route.

=head2 authenticate

Require authentication for all subsequent routes.

=head2 authorize [ $action ]

Require specific authorization for all subsequent routes.

=head1 SEE ALSO

L<Clustericious>, L<Mojolicious::Lite>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
