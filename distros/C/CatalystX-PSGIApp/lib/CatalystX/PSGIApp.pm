package CatalystX::PSGIApp;
BEGIN {
  $CatalystX::PSGIApp::VERSION = '0.01';
}

use strict;
use warnings;
use Catalyst ();

=head1 NAME

CatalystX::PSGIApp - Get a psgi_app in a unified way across different Catalyst versions

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Provides a psgi_app via ->psgi_app if it's available, or via Catalyst::Engine::PSGI if it's not

=head1 OVERVIEW

To use Catalyst with PSGI on Catalyst versions pre 5.9 requires the use of
L<Catalyst::Engine::PSGI>. Version 5.9 (and presumably above) of Catalyst
have PSGI baked in, and provide a C<psgi_app> method.

If your Catalyst app is being run on versions on both side of this divide -
which is a weird use-case you probably shouldn't have - this module allows you
a unified way of getting the PSGI app back.

=head1 WARNINGS

You'll need to use L<Catalyst::Engine::PSGI> installed for this to work with
older Catalysts, but it's not listed as a dependency.

If you need this module, your developers are using different Catalyst versions
to develop against, which is pretty weird.

As per L<Catalyst::PSGI>, Catalyst using the default .psgi file will add
several default middlewares - as we use the C<app_psgi> method explicitly, these
will not be added. See L<Catalyst::PSGI> for details.

=head1 SYNOPSIS

 use CatalystX::PSGIApp;
 my $app = CatalystX::PSGIApp->psgi_app( 'Your::App::Here' );

=head1 METHODS

=head2 psgi_app

Returns a PSGI app, either via C<<->psgi_app>> if your version of Catalyst
supports it, or using L<Catalyst::Engine::PSGI>.

=cut

sub psgi_app {
    my $class  = shift;
    my $target = shift;

    eval "require $target";
    die $@ if $@;

    if ( $target->can('psgi_app') ) {
        return $target->psgi_app;
    } else {
        $target->setup_engine('PSGI');
        return sub { $target->run(@_) }
    }
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>, while at
L<http://www.net-a-porter.com|NET-A-PORTER>.

=cut

1;