use strict;
use warnings;
package App::SimpleHTTPServer;
$App::SimpleHTTPServer::VERSION = '0.002';
# ABSTRACT: Serve up a directory via http simply and easily

BEGIN { @ARGV = qw/ -m production /; }
use Mojolicious::Lite;
use Scalar::Util qw/ looks_like_number /;

our $TESTING = 0;

sub import {
    my $package = shift;
    my $port    = shift;
    if (not looks_like_number $port) {
        unshift @_, $port if defined $port;
        $port   = 8000;
    }
    my $path    = shift;
       $path    = '.' unless defined $path;

    push @{ app->renderer->classes }, __PACKAGE__;
    push @{ app->static->classes }, __PACKAGE__;

    plugin 'Directory::Stylish' => root => $path;

    my @args = (qw/ daemon -l /, "http://*:$port/");
       @args = (qw/ eval /) if $TESTING; # For testing, it needs something to
                                         # do so it doesn't display help message

    app->secrets([qw/ foo /]);
    app->start(@args);
}

1;

=pod

=encoding UTF-8

=head1 NAME

App::SimpleHTTPServer - Serve up a directory via http simply and easily

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  $ # To serve the current directory via http on port 8000, simply do:
  $ perl -MApp::SimpleHTTPServer

  $ # or use the serve_dir script:
  $ serve_dir

=head1 SEE ALSO

L<Mojolicious> - The Mojolicious web framework

L<Mojolicious::Plugin::Directory::Stylish> - The module that actually renders
the directory listing

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut

__DATA__