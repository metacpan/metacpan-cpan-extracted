
package Apache2::ASP::ConfigNode::System;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ConfigNode';
use Apache2::ASP::ConfigNode::System::Settings;


#==============================================================================
sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  $s->{settings} = Apache2::ASP::ConfigNode::System::Settings->new( $s->{settings} || { setting => [ ] } );
  
  return $s;
}# end new()


#==============================================================================
sub libs
{
  my $s = shift;
  
  @{ $s->{libs}->{lib} };
}# end libs()

#==============================================================================
sub load_modules
{
  my $s = shift;
  
  @{ $s->{load_modules}->{module} };
}# end libs()

#==============================================================================
sub env_vars
{
  my $s = shift;
  
  @{ $s->{env_vars}->{var} };
}# end libs()

#==============================================================================
sub post_processors
{
  my $s = shift;
  
  @{ $s->{post_processors}->{class} };
}# end libs()


#==============================================================================
sub settings
{
  my $s = shift;
  
  return wantarray ? @{ $s->{settings}->{setting} } : $s->{settings};
}# end settings()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ConfigNode::System - the 'system' portion of the config.

=head1 SYNOPSIS

  my $system = $Config->system;

=head1 DESCRIPTION

This package provides special access to the elements specific to the C<system>
portion of the XML config file.

=head1 PUBLIC PROPERTIES

=head2 libs

A list of library paths that should be included into C<@INC>.

=head2 load_modules

A list of Perl modules that should be loaded automatically.

=head2 post_processors

A list of L<Apache2::ASP::ConfigPostProcessor> modules that should be given the ability to alter the config before
it is considered "ready for use" by the rest of the application.

=head2 env_vars

A hash of C<%ENV> variables that should be set.

=head2 settings

A collection of special read-only values that should be available throughout the application.

Examples include encryption keys, API keys and username/password combos to access remote services.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut


