
package ASP4::ConfigNode::System;

use strict;
use warnings 'all';
use base 'ASP4::ConfigNode';


sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  
  return $s;
}# end new()


sub libs
{
  my $s = shift;
  
  @{ $s->{libs} || [ ] };
}# end libs()


sub load_modules
{
  my $s = shift;
  
  @{ $s->{load_modules} || [ ] };
}# end load_modules()


sub env_vars
{
  my $s = shift;
  
  $s->{env_vars} || { };
}# end env_vars()


sub post_processors
{
  my $s = shift;
  
  @{ $s->{post_processors} || [ ] };
}# end post_processors()


sub settings
{
  my $s = shift;
  
  return $s->{settings} || { };
}# end settings()

1;# return true:

=pod

=head1 NAME

ASP4::ConfigNode::System - the 'system' portion of the config.

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

A list of L<ASP4::ConfigPostProcessor> modules that should be given the ability to alter the config before
it is considered "ready for use" by the rest of the application.

=head2 env_vars

A hash of C<%ENV> variables that should be set.

=head2 settings

A collection of special read-only values that should be available throughout the application.

Examples include encryption keys, API keys and username/password combos to access remote services.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut


