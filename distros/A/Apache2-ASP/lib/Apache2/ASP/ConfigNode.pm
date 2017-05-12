
package Apache2::ASP::ConfigNode;

use strict;
use warnings 'all';
use Carp 'confess';


#==============================================================================
sub new
{
  my ($class, $ref) = @_;
  local $SIG{__DIE__} = \&Carp::confess;
  my $s = bless $ref, $class;
  $s->init_keys();
  $s;
}# end new()


#==============================================================================
sub init_keys
{
  my $s = shift;
  
  foreach my $key ( grep { ref($s->{$_}) eq 'HASH' } keys(%$s) )
  {
    if( $key eq 'web' )
    {
      require Apache2::ASP::ConfigNode::Web;
      $s->{$key} = Apache2::ASP::ConfigNode::Web->new( $s->{$key} );
    }
    elsif( $key eq 'system' )
    {
      require Apache2::ASP::ConfigNode::System;
      $s->{$key} = Apache2::ASP::ConfigNode::System->new( $s->{$key} );
    }
    else
    {
      $s->{$key} = __PACKAGE__->new( $s->{$key} );
    }# end if()
  }# end foreach()
}# end init_keys()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  confess "Unknown method or property '$name'" unless exists($s->{$name});
  
  # Read-only:
  $s->{$name};
}# end AUTOLOAD()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::ConfigNode - generic configuration element

=head1 SYNOPSIS

  $Config->errors; # Returns a ConfigNode of ConfigNodes.

=head1 DESCRIPTION

All parts of the C<$Config> object are instances of ConfigNode or one of its subclasses.

A ConfigNode is juts a blessed hash with AUTOLOAD behavior that permits read-only behavior.

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


