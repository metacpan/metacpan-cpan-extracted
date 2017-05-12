
package Apache2::ASP::FormHandler;

use strict;
use warnings 'all';
use base 'Apache2::ASP::HTTPHandler';
use vars __PACKAGE__->VARS;

1;# return true:

=pod

=head1 NAME

Apache2::ASP::FormHandler - Base class for form handlers

=head1 SYNOPSIS

  package mysite::contact::form;
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::FormHandler';
  use vars __PACKAGE__->VARS;
  
  sub run {
    my ($s, $context) = @_;
    
    if( my $errors = $s->validate( $context ) ) {
      $Session->{validation_errors} = $errors;
      $Session->{__lastArgs} = $Form;
      return $Response->Redirect( $ENV{HTTP_REFERER} );
    }
    
    # Do stuff:
    
    # Finally:
    return $Response->Redirect( "/some/other/place.asp" );
  }
  
  sub validate {
    my ($s, $context) = @_;
    
    my $errors = { };
    
    # Did they fill out the form?
    foreach my $field (qw/ name email message /) {
      $errors->{$field} = "Required"
        unless $Form->{$field};
    }
    
    return $errors if keys(%$errors);
  }
  
  1;# return true:

=head1 DESCRIPTION

C<Apache2::ASP::FormHandler> is an empty subclass of L<Apache2::ASP::HTTPHandler>
and adds nothing of its own.

It provides a starting point for all other form handlers.

All form handlers should inherit from C<Apache2::ASP::FormHandler> or one of its
subclasses.

Although the author is a B<Big Fan> of MVC, he does not like to be constantly beat 
over the head with the MVC two-by-four.

The style of MVC available here is very much like that found in ASP.Net's MVC, 
though somehow it predates the ASP.Net version by more than 2 years.

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
