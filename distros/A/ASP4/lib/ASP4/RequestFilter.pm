
package ASP4::RequestFilter;

use strict;
use warnings 'all';
use base 'ASP4::HTTPHandler';
use vars __PACKAGE__->VARS;

sub run;

1;# return true:

=pod

=head1 NAME

ASP4::RequestFilter - Filter incoming requests

=head1 SYNOPSIS

  package My::MemberFilter;
  
  use strict;
  use warnings 'all';
  use base 'ASP4::RequestFilter';
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

Then, in your C<asp4-config.json>:

  {
    ...
    "web": {
      ...
      "request_filters": [
        {
          "uri_match":  "/regexp/to/(path|place).*?",
          "class"       "My::MemberFilter"
        },
        {
          "uri_match":  "/regexp/to/(some|other|area).*?",
          "class"       "My::OtherFilter"
        }
      ]
      ...
    },
    ...
  }

=head1 DESCRIPTION

Subclass C<ASP4::RequestFilter> to instantly apply rules to incoming
requests.

These RequestFilters also work for testing via L<ASP4::API>.

=head1 ABSTRACT METHODS

=head2 run( $self, $context )

B<IMPORTANT:> Return C<-1> (or $Response->Declined) to allow the current RequestFilter to be ignored.

Returning anything else...

  return $Response->Redirect("/unauthorized/");

...results in the termination of the current request right away.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=pod

