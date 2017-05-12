#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Stash - Object that contains stored variables 
#
#  DESCRIPTION
#  A simple mechanism for passing objects and variables between calls.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Stash;

use strict;
use warnings;
use base 'Apache2::WebApp::Base';
use Params::Validate qw( :all );

our $VERSION = 0.02;
our $AUTOLOAD;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# set($name, \%vars)
#
# Set the object attribute.  Return a reference to this object.

sub set {
    my ($self, $name, $vars)
      = validate_pos(@_,
          { type => OBJECT },
          { type => SCALAR },
          { type => ARRAYREF | HASHREF | SCALAR | UNDEF }
      );

    $self->{ uc($name) } = $vars;
    return $self->{ uc($name) };
}

#----------------------------------------------------------------------------+
# get($name)
#
# Get the object attribute.  Return a reference to this object.

sub get {
    my ($self, $name)
      = validate_pos(@_,
          { type => OBJECT },
          { type => SCALAR }
      );

    return $self->{ uc($name) };
}

#----------------------------------------------------------------------------+
# AUTOLOAD()
#
# Provides pseudo-methods for read-only access to various internal methods.

sub AUTOLOAD {
    my $self  = shift;
    my $method;
    ($method = $AUTOLOAD) =~ s/.*:://;
    return if ($method eq 'DESTROY');
    return $self->{ uc($method) };
}

1;

__END__

=head1 NAME

Apache2::WebApp::Stash - Object that contains stored variables

=head1 SYNOPSIS

  my %vars = (
      foo => 'bar',
      baz => qw( bucket1 bucket2 bucket3 ),
      qux => {
          key1 => 'value1',
          key2 => 'value2',
          ...
      },
      ...
    );

  $c->stash( 'global', \%vars );

  # program continues...

  my $vars = $c->stash('global');

  print  $vars->{foo};              # returns 'bar'
  print @$vars->{baz}               # returns 3
  print  $vars->{qux}->{key1};      # returns 'value1'

=head1 DESCRIPTION

A simple mechanism for passing objects and variables between calls.

=head1 SEE ALSO

L<Apache2::WebApp>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
