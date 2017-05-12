
package Apache2::ASP::ModPerl2CGI;

use strict;
use warnings;
use base 'CGI::Apache2::Wrapper';
use Apache2::ASP::SimpleCGI;
use Carp 'confess';


#==============================================================================
sub new
{
  my ($class, $r, $upload_hook) = @_;

  my $s = $class->SUPER::new( $r );
  $s->{r} = $r;
  if( ref($upload_hook) eq 'CODE' )
  {
    my $req = Apache2::Request->new(
      $r,
      UPLOAD_HOOK => $upload_hook,
    );
    $s->req(
      $req
    );
  }
  else
  {
    $s->req( Apache2::Request->new( $r ) );
  }# end if()
  
  return $s;
}# end new()


#==============================================================================
sub escape
{
  my ($s, $str) = @_;
  
  return Apache2::ASP::SimpleCGI->escape( $str );
}# end escape()


#==============================================================================
sub unescape
{
  my ($s, $str) = @_;
  
  return Apache2::ASP::SimpleCGI->unescape( $str );
}# end unescape()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  eval { return $s->{r}->$name( @_ ) };
  confess $@ if $@;
}# end AUTOLOAD()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  delete($s->{$_}) foreach keys(%$s);
}# end DESTROY()


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::ModPerl2CGI - A wrapper for CGI utility functions.

=head1 DESCRIPTION

Uses L<CGI::Apache2::Wrapper> behind the scenes.  Handles file uploads and parsing form data.

Generally only used within C<Apache2::ASP> classes, so casual users don't have to worry about
this module too much.

=head1 METHODS

=head2 new( $r [, \&upload_hook] )

Returns a new C<Apache2::ASP::ModPerl2CGI> object - with or without an upload hook specified.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
