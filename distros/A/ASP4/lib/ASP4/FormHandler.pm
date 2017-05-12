
package ASP4::FormHandler;

use strict;
use warnings 'all';
use base 'ASP4::HTTPHandler';
use vars __PACKAGE__->VARS;

1;# return true:

=pod

=head1 NAME

ASP4::FormHandler - Base class for all form handlers

=head1 SYNOPSIS

  package my::handler;
  
  use strict;
  use warnings 'all';
  use base 'ASP4::FormHandler';
  
  # Import $Request, $Response, $Session, $Server, $Form, $Config, $Stash
  use vars __PACKAGE__->VARS;
  
  sub run {
    my ($self, $context) = @_;
    
    $Response->Write("Hello, World!");
  }
  
  1;# return true:

=head1 DESCRIPTION

All ASP4 *.asp scripts and C</handlers/*> classes should inherit from C<ASP4::FormHandler>.

=head1 PROPERTIES

=head2 VARS

Returns the list of variable names of the ASP4 intrinsic objects.

  $Request      $Response
  $Session      $Server
  $Config       $Form
  $Stash

=head1 METHODS

=head2 before_run( $self, $context )

Called before C<run> - can be used to deny access or redirect elsewhere under
special conditions.

=head2 run( $self, $context )

Where most of your action is expected to occur.

=head2 after_run( $self, $context )

Called after C<run>, can be used

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

