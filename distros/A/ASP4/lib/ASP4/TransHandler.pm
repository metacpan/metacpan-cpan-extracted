

package ASP4::TransHandler;

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
  
  $ENV{DOCUMENT_ROOT}   = $r->document_root;
  $ENV{REMOTE_ADDR}     = $r->connection->get_remote_host();
  $ENV{HTTP_HOST}       = $r->hostname;
  
  return -1;
}# end handler()

1;# return true:

=pod

=head1 NAME

ASP4::TransHandler - PerlTransHandler with access to ASP4::Config

=head1 SYNOPSIS

  package My::TransHandler;
  
  use strict;
  use warnings 'all';
  use base 'ASP4::TransHandler';
  use ASP4::ConfigLoader;
  
  sub handler : method {
    my ($class, $r) = @_;
    
    my $super_response = $class->SUPER::handler( $r );
    
    my $config = ASP4::ConfigLoader->load();
    
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

C<ASP4::TransHandler> is a utility class that helps module authors take advantage
of the ASP4 configuration without actually doing any of the work.

=head2 RequestFilters vs TransHandlers

The difference between TransHandlers and L<ASP4::RequestFilter>s is that
within a RequestFilter, you have access to all of the normal ASP objects ($Request, $Response, $Session, etc).

In a TransHandler, you only have access to the L<Apache2::RequestRec> C<$r> and the 
L<ASP4::Config> (and only then if you load it up yourself via L<ASP4::ConfigLoader>.

B<NOTE>: - TransHandlers are configured in the C<httpd.conf> and are only executed
in a real Apache2 httpd environment.  They are not executed during testing or via
L<ASP4::API>.

TransHandlers are a handy way of jumping into "normal" mod_perl handler mode without
losing access to your web application's config.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut


