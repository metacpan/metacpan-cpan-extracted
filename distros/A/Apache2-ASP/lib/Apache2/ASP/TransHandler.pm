

package Apache2::ASP::TransHandler;

use strict;
use APR::Table ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::SubRequest ();
use Apache2::Const -compile => ':common';
use Apache2::ServerRec ();


#==============================================================================
sub handler : method
{
  my ($class, $r) = @_;
  
  $ENV{DOCUMENT_ROOT} ||= $r->document_root;
  
  return -1;
}# end handler()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::TransHandler - PerlTransHandler with access to Apache2::ASP::Config

=head1 SYNOPSIS

  package My::TransHandler;
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::TransHandler';
  use Apache2::ASP::ConfigLoader;
  
  sub handler : method {
    my ($class, $r) = @_;
    
    my $super_response = $class->SUPER::handler( $r );
    
    my $config = Apache2::ASP::ConfigLoader->load();
    
    # Do stuff...
    calculate_pi_to_the_billionth_decimal_place();
    
    # Finally...
    return $super_response;
  }
  
  1;# return true:

Then, in your httpd.conf:

  <Perl>
    push @INC, '/path/to/your/libs';
  </Perl>

  <VirtualHost *:80>
    ...
    PerlTransHandler My::TransHandler
    ...
  </VirtualHost>

=head1 DESCRIPTION

C<Apache2::ASP::TransHandler> is

=head2 RequestFilters vs TransHandlers

The difference between TransHandlers and L<Apache2::ASP::RequestFilter>s is that
within a RequestFilter, you have access to all of the normal ASP objects ($Request, $Response, $Session, etc).

In a TransHandler, you only have access to the L<Apache2::RequestRec> C<$r> and the 
L<Apache2::ASP::Config> (and only then if you load it up yourself via L<Apache2::ASP::ConfigLoader>.

B<NOTE>: - TransHandlers are configured in the C<httpd.conf> and are only executed
in a real Apache2 httpd environment.  They are not executed during testing or via
L<Apache2::ASP::API>.

TransHandlers are a handy way of jumping into "normal" mod_perl handler mode without
losing access to your web application's config.

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

