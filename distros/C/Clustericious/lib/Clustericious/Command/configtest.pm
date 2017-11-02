package Clustericious::Command::configtest;

use strict;
use warnings;
use 5.010;
use Mojo::Base 'Clustericious::Command';

# ABSTRACT: Test a Clustericious application's configuration
our $VERSION = '1.27'; # VERSION


has description => <<EOT;
Load configuration and test for errors
EOT

has usage => <<EOT;
usage $0: configtest
Load configuration and test for errors
EOT

sub run
{
  my($self, @args) = @_;
  exit 2 unless $self->app->sanity_check;
  say 'config okay';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::configtest - Test a Clustericious application's configuration

=head1 VERSION

version 1.27

=head1 SYNOPSIS

Your app:

 package YourApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 sub sanity_check
 {
   my($self) = @_;
   # ... return true if sane, return false otherwise
   unless($self->config->foo(default => '') eq 'bar')
   {
     say 'your config should set foo to bar';
     return 0;
   }
   
   return 1;
 }
 
 1;

do a sanity check of the configuration:

 % yourapp configtest

=head1 DESCRIPTION

This command does a basic sanity check on the configuration for your Clustericious
application, and calls the application's C<sanity_check>

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
