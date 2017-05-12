package Clustericious::Plugin::ClustericiousHelpers;

use strict;
use warnings;
use 5.010001;
use Carp qw( carp );
use base qw( Mojolicious::Plugin );
use Mojo::ByteStream qw( b );

# ABSTRACT: Helpers for Clustericious
our $VERSION = '1.24'; # VERSION


sub register
{
  my ($self, $app, $conf) = @_;


  $app->helper(render_moved => sub {
    my($c,@args) = @_;
    $c->res->code(301);
    my $where = $c->url_for(@args)->to_abs;
    $c->res->headers->location($where);
    $c->render(text => "moved to $where");
  });


  do {
    my $client_class = ref($app) . "::Client";
    $client_class = 'Clustericious::Client'
      unless $client_class->can('new')
      ||     eval qq{ require $client_class; $client_class->can('new') };

    $app->helper(client => sub {
      $client_class->new(config => $app->config);
    });
  };

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Plugin::ClustericiousHelpers - Helpers for Clustericious

=head1 VERSION

version 1.24

=head1 DESCRIPTION

This class provides helpers for Clustericious.

=head1 HELPERS

In addition to the helpers provided by
L<Mojolicious::Plugin::DefaultHelpers> you get:

=head2 render_moved

 $c->render_moved($path);

Render a 301 response.

=head2 client

 my $client = $c->client;

Returns the appropriate L<Clustericious::Client> object for your app.

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
