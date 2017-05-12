
package Apache2::ASP::ConfigFinder;

use strict;
use warnings 'all';
use Cwd 'cwd';

our $CONFIGFILE = 'apache2-asp-config.xml';

#==============================================================================
sub config_path
{
  my $path = $CONFIGFILE;
  
  my $root = $ENV{DOCUMENT_ROOT} || cwd();
  
  # Try test dir:
  if( -f "$root/t/conf/$CONFIGFILE" )
  {
    return "$root/t/conf/$CONFIGFILE";
  }# end if()
  
  # Start moving up:
  for( 1...10 )
  {
    my $path = "$root/conf/$CONFIGFILE";
    return $path if -f $path;
    $root =~ s/\/[^\/]+$//
      or last;
  }# end for()
  
  die "CANNOT FIND '$CONFIGFILE' anywhere under '$root'";
}# end config_path()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::ConfigFinder - Universal configuration finder

=head1 SYNOPSIS

  # You will probably never use this class, but...
  
  use Apache2::ASP::ConfigFinder;
  
  my $path_to_config = Apache2::ASP::ConfigFinder->config_path();

=head1 DESCRIPTION

Finding the configuration is sometimes impossible in web applications.

This package makes it trivial.  However you will probably never use this class
directly.  Use L<Apache2::ASP::ConfigLoader> instead.

=head1 PUBLIC METHODS

=head2 config_path( )

Returns the full path to the current configuration file - i.e. C</usr/local/projects/mysite.com/conf/apache2-asp-config.xml>.

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

