
package Apache2::ASP::RequestFilter;

use strict;
use warnings 'all';
use base 'Apache2::ASP::HTTPHandler';

sub run;

1;# return true:

=head1 NAME

Apache2::ASP::RequestFilter - Filter incoming requests

=head1 SYNOPSIS

  package My::MemberFilter;
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::RequestFilter';
  use vars __PACKAGE__->VARS;
  
  sub run {
    my ($self, $context) = @_;
    
    if( $Session->{is_logged_in} )
    {
      # The user is logged in - we can ignore this request:
      return $Response->Declined;
    }
    else
    {
      # The user must authenticate first:
      $Session->{validation_errors} = { general => "You must log in first" };
      return $Response->Redirect("/login/");
    }# end if()
  }
  
  1;# return true:

Then, in your C<apache2-asp-config.xml>:

  <config>
    ...
    <web>
      ...
      <request_filters>
        <filter>
          <uri_match>/members/*</uri_match>
          <class>My::MemberFilter</class>
        </filter>
        ...
      </request_filters>
    </web>
    ...
  </config>

=head1 DESCRIPTION

Subclass C<Apache2::ASP::RequestFilter> to instantly apply rules to incoming
requests.

These RequestFilters also work for testing via L<Apache2::ASP::Test::Base> and
L<Apache2::ASP::API>.

=head2 RequestFilters vs TransHandlers

The difference between RequestFilters and L<Apache2::ASP::TransHandler>s is that
within a RequestFilter, you have access to all of the normal ASP objects ($Request, $Response, $Session, etc).

In a TransHandler, you only have access to the L<Apache2::RequestRec> C<$r> and the 
L<Apache2::ASP::Config> (and only then if you load it up yourself via L<Apache2::ASP::ConfigLoader>.

B<NOTE>: - TransHandlers are configured in the C<httpd.conf> and are only executed
in a real Apache2 httpd environment.  They are not executed during testing or via
L<Apache2::ASP::API>.

=head1 ABSTRACT METHODS

=head2 run( $self, Apache2::ASP::HTTPContext $context )

Return C<-1> (or $Response->Declined) to allow the current RequestFilter to be ignored.

Returning anything else...

  return $Response->Redirect("/unauthorized/");

...results in the termination of the current request right away.

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

