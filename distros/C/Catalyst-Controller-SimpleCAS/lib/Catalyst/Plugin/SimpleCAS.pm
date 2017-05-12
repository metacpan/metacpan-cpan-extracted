package Catalyst::Plugin::SimpleCAS;
use strict;
use warnings;

our $VERSION = '1.001';

use Moose::Role;
use namespace::autoclean;

use CatalystX::InjectComponent;
use Catalyst::Controller::SimpleCAS;

after 'setup_components' => sub { (shift)->inject_simplecas_controller(@_) };

sub _simplecas_controller_namespace {
  my $c = shift;
  my $cfg = $c->config->{'Plugin::SimpleCAS'} || {};
  $cfg->{controller_namespace} || 'SimpleCAS'
}

sub inject_simplecas_controller {
  my $c = shift;

  # Now inject the new Controllers:
  CatalystX::InjectComponent->inject(
    into => $c,
    component => 'Catalyst::Controller::SimpleCAS',
    as => join('::','Controller',$c->_simplecas_controller_namespace)
  );
}

# Convenience method to be able to get the controller via $c->CAS
sub CAS {
  my $c = shift;
  $c->controller( $c->_simplecas_controller_namespace )
}


1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::SimpleCAS - Plugin interface to L<Catalyst::Controller::SimpleCAS>

=head1 SYNOPSIS

  use Catalyst;
  with 'Catalyst::Plugin::SimpleCAS';
  

Later on, in your scripts or other backend code:

  my $c = 'MyApp';
  my $CAS = $c->CAS; # sugar to get the Controller instance
  
  # Add content as a string/scalar:
  my $sha1 = $CAS->add("My cool text!\nbla bla bla");
  
  # Add content from a file:
  my $sha1 = $CAS->add("/path/to/regular/file");
  
  # Add content by supplying a filehandle:
  my $fh = Path::Class::File::file("/path/to/regular/file")->openr;
  my $sha1 = $CAS->add($fh);
  
  
  # Fetch content as a string/scalar:
  my $data = $CAS->fetch($sha1);
  
  # Fetch content as a filehandle:
  my $data = $CAS->fetch_fh($sha1);


=head1 DESCRIPTION

This class provides a simple Catalyst Plugin interface to L<Catalyst::Controller::SimpleCAS>.
All it does is inject the SimpleCAS controller into the application and sets up the sugar 
method C<CAS> in the main app class/context (C<$c>).

This module was originally developed for and within L<RapidApp> before being extracted into its 
own module. This module provides server-side functionality which can be used for any Catalyst 
application, however, it is up to the developer to write the associated front-end interfaces to 
consume its API (unless you are using RapidApp to begin with).

See L<Catalyst::Controller::SimpleCAS> for more information and API documentation.

=head1 CONFIG PARAMS

=head2 controller_namespace

Namespace of the SimpleCAS controller to inject. Defaults to 'SimpleCAS'

=head1 METHODS

=head2 CAS

Convenience method to return the SimpelCAS controller. Assuming the C<controller_namespace>
is left at its default, these are equivelent:

  my $CAS = $c->controller('SimpleCAS');
  
  # same as:
  my $CAS = $c->CAS;

=head2 inject_simplecas_controller

Method which gets called automatically that does the actual injection of the controller into
the Catalyst application. Should never be called directly. It is being provided in case the
need arises to hook at this point in the code (i.e. with an around modifier)

=head1 SEE ALSO

=over

=item L<Catalyst::Controller::SimpleCAS>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
