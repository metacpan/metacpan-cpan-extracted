
package Apache2::ASP::ConfigPostProcessor;

use strict;
use warnings 'all';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub post_process($$);

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ConfigPostProcessor - Base class for configuration post-processors

=head1 SYNOPSIS

  package My::ConfigPostProcessor;
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::ConfigPostProcessor';
  
  sub post_process {
    my ($self, $config) = @_;
    
    $config->{mood} = 'Happy';
    
    # Don't forget to return the new $config object:
    return $config;
  }
  
  1;# return true:

Then, in the C<apache2-asp-config.xml>:

  <?xml version="1.0"?>
  <config>
    ...
    <system>
      ...
      <post_processors>
        <class>My::PostProcessor</class>
        ...
      </post_processors>
      ...
    </system>
    ...
  </config>

Then, somewhere else in the web application...

  if( $Config->mood eq 'Happy' ) {
    # Don't worry - be happy :)
  }

=head1 ABSTRACT METHODS

All subclasses must implement the following method(s) at a minimum:

=head2 post_process( $self, Apache2::ASP::Config $Config )

Should do B<something> to the $Config object, B<and then *return* that new $Config object>.

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

