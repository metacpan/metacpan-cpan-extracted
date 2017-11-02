package Clustericious::Plugin::CommonRoutes;

use strict;
use warnings;
use 5.010;
use Mojo::Base 'Mojolicious::Plugin';
use File::Basename ();
use Sys::Hostname ();
use List::Util qw/ uniq /;

# ABSTRACT: Routes common to all clustericious applications
our $VERSION = '1.27'; # VERSION


sub register
{
  my($self, $app) = @_;

  $app->plugin('Clustericious::Plugin::AutodataHandler')
    unless $app->renderer->handlers->{autodata};


  my $version = do {
    my $class = ref $app;
    $class = eval { $app->renderer->classes->[0] } // 'main' if $class eq 'Mojolicious::Lite';
    $class->VERSION // 'dev';
  };

  $app->routes->get('/version')->to(cb => sub {
    shift->stash(autodata => [ $version ]);
  });


  my($app_name, $hostname) = do {
    my $name = ref $app;
    $name = File::Basename::basename($0) if $name eq 'Mojolicious::Lite';
    ($name, Sys::Hostname::hostname());
  };

  $app->routes->get('/status')->to(cb => sub {
    my($self) = @_;
    $self->stash(autodata => {
      app_name        => $app_name,
      server_version  => $version,
      server_hostname => $hostname,
      server_url      => $self->url_for('/')->to_abs->to_string,
    });
  });


  $app->routes->get('/api')->to(cb => sub {
    shift->render( autodata => [ __PACKAGE__->_dump_api($app) ]);
  });


  $app->routes->get('/api/:table')->to(cb => sub {
    my($self) = @_;
    my $table = __PACKAGE__->_dump_api_table($self->stash('table'));
    $table ? $self->render( autodata => $table ) : $self->reply->not_found;
  });
  

  $app->routes->get('/log/:lines' => [ lines => qr/\d+/ ] => sub {
    my($self) = @_;
    my $lines = $self->stash("lines");
    unless ($self->config->export_logs(default => 0))
    {
      return $self->render(text => 'logs not available');
    }
    $self->render(text => Clustericious::Log->tail(lines => $lines || 10) || '** empty log **');
  }) if $app->isa('Clustericious::App');

  $app->routes->options('/*opturl' => { opturl => '' } => sub {
    my($self) = @_;
    $self->res->headers->add( 'Access-Control-Allow-Methods' => 'GET, POST, OPTIONS' );
    # Allow-Origin and Allow-Headers added in after_dispatch hook.
    $self->render(text => 'ok');
  });
}

sub _have_rose
{
  Rose::Planter->can('tables') ? 1 : 0;
}

sub _dump_api {
  my $class = shift;
  my $app = shift;
  my $routes = shift || $app->routes->children;
  my @all;

  for my $r (@$routes)
  {
    my $pat = $r->pattern;
    $pat->_compile;
    my %placeholders = map { $_ => "<$_>" } @{ $pat->placeholders };
    my $method = uc join ',', @{ $r->via || ["GET"] };
    if (_have_rose() && $placeholders{table})
    {
      for my $table (Rose::Planter->tables)
      {
        $placeholders{table} = $table;
        my $pat = $pat->unparsed;
        $pat =~ s/:table/$table/;
        push @all, "$method $pat";
      }
    }
    elsif (_have_rose() && $placeholders{items})
    {
      for my $plural (Rose::Planter->plurals)
      {
        $placeholders{items} = $plural;
        my $line = $pat->render(\%placeholders);
        push @all, "$method $line";
      }
    }
    elsif (defined($pat->unparsed))
    {
      push @all, join ' ', $method, $pat->unparsed;
    }
    else
    {
      push @all, $class->_dump_api($app, $r->children);
    }
  }
  return uniq sort @all;
}

sub _dump_api_table_types
{
  my(undef, $rose_type) = @_;
  return 'datetime' if $rose_type =~ /^datetime/;
  state $types = {
    (map { $_ => 'string' } qw( character text varchar )),
    (map { $_ => 'numeric' } 'numeric', 'float', 'double precision','decimal'),
    (map { $_ => $_ } qw( blob set time interval enum bytea chkpass bitfield date boolean )),
    (map { $_ => 'integer' } qw( bigint integer bigserial serial )),
    (map { $_ => 'epoch' } 'epoch', 'epoch hires'),
    (map { $_ => 'timestamp' } 'timestamp', 'timestamp with time zone'),
  };
  return $types->{$rose_type} // 'unknown';
}

sub _dump_api_table
{
  my(undef, $table) = @_;
  return unless _have_rose();
  my $class = Rose::Planter->find_class($table);
  return unless defined $class;

  return {
    columns => {
      map {
        $_->name => {
          rose_db_type => $_->type,
          not_null     => $_->not_null,
          type         => __PACKAGE__->_dump_api_table_types($_->type),
        } } $class->meta->columns
    },
    primary_key => [
      map { $_->name } $class->meta->primary_key_columns
    ],
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Plugin::CommonRoutes - Routes common to all clustericious applications

=head1 VERSION

version 1.27

=head1 SYNOPSIS

 # Mojolicious
 $self->plugin('Clustericious::Plugin::CommonRoutes');
 
 # Clustericious
 # ... included by default ...

=head1 DESCRIPTION

This plugin adds routes that are common to all clustericious servers.
It is available to Vanilla L<Mojolicious> apps that want to work with
L<Clustericious::Client> based clients.

=head2 /version

Returns the version of the service as a single element list.

=head2 /status

Returns status information about the service.  This comes back
as a hash that includes these key/value pairs:

=over 4

=item app_name

The name of the application (example: "MyApp")

=item server_hostname

The server on which the service is running.

=item server_url

The URL to use for the service.

=item server_version

The version of the application.

=back

=head2 /api

Returns a list of API routes for the service.  This is similar to the information
provided by the L<Mojolicious::Command::routes|routes command>.

=head2 /api/:table

If you are using L<Module::Build::Database> and L<Route::Planter> for a database
back end to your  application you can get the columns of each table using this route.

=head2 /log/:lines

Return the last several lines from the application log (number specified by :lines
and defaults to 10 if not specified).

Only available if you set export_logs to true in your application's server configuration.

example C<~/etc/MyApp.conf>:

 ---
 export_logs: 1

This route is NOT made available to non L<Clustericious> applications.

=head1 CAVEATS

This plugin pulls in the L<Clustericious::Plugin::AutodataHandler> plugin if
it hasn't already been loaded.

=head1 SEE ALSO

L<Clustericious>, L<Clustericious::RouteBuilder>

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
