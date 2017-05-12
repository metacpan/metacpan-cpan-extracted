package Clustericious::Command::plackup;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Mojo::Server::PSGI;
use base 'Clustericious::Command';
use File::Which qw( which );
use Mojo::URL;

# ABSTRACT: Clustericious command to start plack server
our $VERSION = '1.24'; # VERSION


__PACKAGE__->attr(description => <<EOT);
Start a plack server (see plackup)
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: plackup [plackup options]
Starts a plack server.  See plackup for valid options.
EOT

sub run {
  my($self, @args) = @_;
  my $app_name = $ENV{MOJO_APP};
  
  $self->app->init_logging;

  my $plackup = which('plackup') || LOGDIE "could not find plackup in $ENV{PATH}";

  my $url = Mojo::URL->new($self->app->config->url);
  LOGDIE "@{[ $url->scheme ]} not supported" if $url->scheme ne 'http';
  
  shift @args if defined $args[0] && $args[0] eq 'plackup';
  push @args, $0;
  unshift @args, '--port' => $url->port;
  unshift @args, '--host' => $url->host;
  
  #if(my $pid_file = $self->app->config->plackup(default => {})->pid_file(default => 0))
  #{
  #  unshift @args, '--pidfile' => $pid_file;
  #}
  
  DEBUG "starting $plackup @args";
  delete $ENV{MOJO_COMMANDS_DONE};
  exec $plackup, @args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::plackup - Clustericious command to start plack server

=head1 VERSION

version 1.24

=head1 SYNOPSIS

 % yourapp plackup

=head1 DESCRIPTION

Start a plack server using plackup.  By default plackup does not daemonize into the
background, making it a handy development server.  Any arguments will be passed into
the plackup command directly.

=head1 SEE ALSO

L<Clustericious>, L<plackup>, L<Plack>

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
