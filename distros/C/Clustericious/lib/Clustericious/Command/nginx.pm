package Clustericious::Command::nginx;

use strict;
use warnings;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw( mkpath );
use base 'Clustericious::Command';
use Clustericious::Log;
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat nginx
our $VERSION = '1.29'; # VERSION


__PACKAGE__->attr(description => <<EOT);
Start an nginx web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: nginx -p <prefix> [...other nginx options]
Starts an nginx webserver.
Options are passed verbatim to the nginx executable.
EOT

sub run {
  my($self, @args) = @_;
  my $app_name = $ENV{MOJO_APP};
  my %args = @args;

  $self->app->init_logging;

  my $prefix = $args{-p} or INFO "no prefix for nginx";
  mkpath "$prefix/logs";

  my $nginx = which('nginx') or LOGDIE "could not find nginx in $ENV{PATH}";
  DEBUG "starting $nginx @args";
  system$nginx, @args;
  die "'$nginx @args' Failed to execute: $!" if $? == -1;
  die "'$nginx @args' Killed with signal: ", $? & 127 if $? & 127;
  die "'$nginx @args' Exited with ", $? >> 8 if $? >> 8;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::nginx - Clustericious command to stat nginx

=head1 VERSION

version 1.29

=head1 DESCRIPTION

Start an nginx web server.

=head1 NAME

Clustericious::Command::nginx - Clustericious command to stat nginx

=head1 EXAMPLES

=head2 nginx proxy

 ---
 % my $root = dir "@{[ home ]}/var/run";
 % $root->mkpath(0,0700);
 
 url: http://<%= $host %>:<%= $port %>
 start_mode:
   - hypnotoad
   - nginx
 
 nginx:
   args: -p <%= $root %>/nginx.<%= $port %>/
   autogen:
     filename: <%= $root %>/nginx.<%= $port %>/conf/nginx.conf
     content: |
       worker_processes auto;
       events {
         use epoll;
         worker_connections 4096;
       }
       http {
         server {
           listen <%= $host %>:<%= $port %>;
           location / {
             proxy_pass http://127.0.0.1:<%= $port %>;
             proxy_http_version 1.1;
             proxy_read_timeout 300;
           }
         }
       }
 
 hypnotoad:
   listen:
     - http://127.0.0.1:<%= $port %>
   pid_file: <%= $root %>/hypnotoad.<%= $port %>.pid

=head1 SEE ALSO

L<Clustericious>

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
