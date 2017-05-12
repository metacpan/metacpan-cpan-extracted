package Articulate::Role::Component;
use strict;
use warnings;
use Moo::Role;

=head1 NAME

Articulate::Role::Component - access the core app and other compnents

=cut

=head1 DESCRIPTION

This role provides accessors so that components can refer to each
other. In order to do so they must when created or first called, have
their C<app> attribute set.

=head1 ATTRIBUTE

=head3 app

The Articulate app to which this component belongs.

=head1 METHODS

Each of these methods are simple read-only accessors which use the
C<app> attribute to find the relevant component.

=head3 augmentation

Provides access to the app's augmentation component.

=head3 authentication

Provides access to the app's authentication component.

=head3 authorisation

Provides access to the app's authorisation component.

=head3 caching

Provides access to the app's caching component.

=head3 construction

Provides access to the app's construction component.

=head3 enrichment

Provides access to the app's enrichment component.

=head3 framework

Provides access to the app's framework component.

=head3 navigation

Provides access to the app's navigation component.

=head3 serialisation

Provides access to the app's serialisation component.

=head3 service

Provides access to the app's service component.

=head3 storage

Provides access to the app's storage component.

=head3 validation

Provides access to the app's validation component.

=cut

has app => (
  is       => 'rw',
  weak_ref => 1,
);

sub augmentation   { shift->app->components->{'augmentation'} }
sub authentication { shift->app->components->{'authentication'} }
sub authorisation  { shift->app->components->{'authorisation'} }
sub construction   { shift->app->components->{'construction'} }
sub enrichment     { shift->app->components->{'enrichment'} }
sub framework      { shift->app->components->{'framework'} }
sub navigation     { shift->app->components->{'navigation'} }
sub serialisation  { shift->app->components->{'serialisation'} }
sub service        { shift->app->components->{'service'} }
sub storage        { shift->app->components->{'storage'} }
sub validation     { shift->app->components->{'validation'} }
sub caching        { shift->app->components->{'caching'} }

1;
