require 5.006_001;

use strict;
use warnings;

#======================================================================
# Authen::CAS::Client::Response
#
package Authen::CAS::Client::Response;

our $VERSION = '0.03';

sub _ATTRIBUTES () { _ok => undef, doc => undef }

sub new {
  my ( $class, %args ) = @_;

  my %self = $class->_ATTRIBUTES;
  for my $attribute ( keys %self ) {
    $self{$attribute} = $args{$attribute}
      if exists $args{$attribute};
  }

  bless \%self, $class
}

sub is_error   { my ( $self ) = @_; ! defined $self->{_ok} }
sub is_failure { my ( $self ) = @_;   defined $self->{_ok} && ! $self->{_ok} }
sub is_success { my ( $self ) = @_;   defined $self->{_ok} &&   $self->{_ok} }

sub doc        { my ( $self ) = @_; $self->{doc} }


#======================================================================
# Authen::CAS::Client::Response::Error
#
package Authen::CAS::Client::Response::Error;

use base qw/ Authen::CAS::Client::Response /;

sub _ATTRIBUTES () { error => 'An internal error occurred', $_[0]->SUPER::_ATTRIBUTES }

sub new { my $class = shift; $class->SUPER::new( @_, _ok => undef ) }

sub error { my ( $self ) = @_; $self->{error} }


#======================================================================
# Authen::CAS::Client::Response::Failure
#
package Authen::CAS::Client::Response::Failure;

use base qw/ Authen::CAS::Client::Response /;

sub _ATTRIBUTES () { code => undef, message => '', $_[0]->SUPER::_ATTRIBUTES }

sub new { my $class = shift; $class->SUPER::new( @_, _ok => 0 ) }

sub code    { my ( $self ) = @_; $self->{code} }
sub message { my ( $self ) = @_; $self->{message} }


#======================================================================
# Authen::CAS::Client::Response::AuthFailure
#
package Authen::CAS::Client::Response::AuthFailure;

use base qw/ Authen::CAS::Client::Response::Failure /;


#======================================================================
# Authen::CAS::Client::Response::ProxyFailure
#
package Authen::CAS::Client::Response::ProxyFailure;

use base qw/ Authen::CAS::Client::Response::Failure /;


#======================================================================
# Authen::CAS::Client::Response::Success
#
package Authen::CAS::Client::Response::Success;

use base qw/ Authen::CAS::Client::Response /;

sub new { my $class = shift; $class->SUPER::new( @_, _ok => 1 ) }


#======================================================================
# Authen::CAS::Client::Response::AuthSuccess
#
package Authen::CAS::Client::Response::AuthSuccess;

use base qw/ Authen::CAS::Client::Response::Success /;

sub _ATTRIBUTES () { user => undef, iou => undef, proxies => [ ], $_[0]->SUPER::_ATTRIBUTES }

sub user    { my ( $self ) = @_; $self->{user} }
sub iou     { my ( $self ) = @_; $self->{iou} }
sub proxies { my ( $self ) = @_; wantarray ? @{ $self->{proxies} } : [ @{ $self->{proxies} } ] }


#======================================================================
# Authen::CAS::Client::Response::ProxySuccess
#
package Authen::CAS::Client::Response::ProxySuccess;

use base qw/ Authen::CAS::Client::Response::Success /;

sub _ATTRIBUTES () { proxy_ticket => undef, $_[0]->SUPER::_ATTRIBUTES }

sub proxy_ticket { my ( $self ) = @_; $self->{proxy_ticket} }


1
__END__

=pod

=head1 NAME

Authen::CAS::Client::Response - A set of classes for implementing
responses from a CAS server

=head1 DESCRIPTION

Authen::CAS::Client::Response implements a base class that is used to
build a hierarchy of response objects that are returned from methods in
L<Authen::CAS::Client>.  Most response objects are meant to encapsulate
a type of response from a CAS server.

=head1 CLASSES AND METHODS

=head2 Authen::CAS::Client::Response

Authen::CAS::Client::Response is the base class from which all other
response classes inherit.  As such it is very primitive and is never
used directly.

=head3 new( %args )

C<new()> creates an instance of an C<Authen::CAS::Client::Response> object
and assigns its data members according to the values in C<%args>.

=head3 is_error()

C<is_error()> returns true if the response represents an error object.

=head3 is_failure()

C<is_failure()> returns true if the response represents a failure object.

=head3 is_success()

C<is_success()> returns true if the response represents a success object.

=head3 doc()

C<doc()> returns the response document used to create the response object.
For errors and CAS v1.0 requests this will be the raw text response
from the server.  Otherwise an L<XML::LibXML> object will be returned.
This can be used for debugging or retrieving additional information
from the CAS server's response.

=head2 Authen::CAS::Client::Response::Error

Authen::CAS::Client::Response::Error is used when an error occurs that
prevents further processing of a request.  This would include not being able
connect to the CAS server, receiving an unexpected response from the server
or being unable to correctly parse the server's response according to the
guidelines in the CAS protocol specification.

=head3 new( error =E<gt> $error, doc =E<gt> $doc )

C<new()> creates an instance of an C<Authen::CAS::Client::Response::Error>
object.  C<$error> is the error string.  C<$doc> is the response document.

=head3 error()

C<error()> returns the error string.

=head2 Authen::CAS::Client::Response::Failure

Authen::CAS::Client::Response::Failure is used as a base class for other
failure responses.  These correspond to the C<cas:authenticationFailure> and
C<cas:proxyFailure> server responses outlined in the CAS protocol
specification.

=head3 new( code =E<gt> $code, message =E<gt> $message, doc =E<gt> $doc )

C<new()> creates an instance of an C<Authen::CAS::Client::Response::Failure>
object.  C<$code> is the failure code.  C<$message> is the failure message.
C<$doc> is the response document.

=head3 code()

C<code()> returns the failure code.

=head3 message()

C<message()> returns the failure message.

=head2 Authen::CAS::Client::Response::AuthFailure

Authen::CAS::Client::Response::AuthFailure is a subclass of
C<Authen::CAS::Client::Response::Failure> and is used when a
validation attempt fails.  When using the CAS v2.0 protocol,
C<$code>, C<$message> and C<$doc> are set according to what is parsed
from the server response.  When using the CAS v1.0 protocol, C<$code>
is set to C<'V10_AUTH_FAILURE'>, C<$message> is set to the empty string
and C<$doc> is set to the server's response content.

No additional methods are defined.

=head2 Authen::CAS::Client::Response::ProxyFailure

Authen::CAS::Client::Response::ProxyFailure is a subclass of
C<Authen::CAS::Client::Response::Failure> and is used when a
C<cas:proxyFailure> response is received from the CAS server
during a proxy attempt.  C<$code>, C<$message> and C<$doc> are set
according to what is parsed from the server response.

No additional methods are defined.

=head2 Authen::CAS::Client::Response::Success

C<Authen::CAS::Client::Response::Success> is used as base class for other
success responses.  These correspond to the C<cas:authenticationSuccess> and
C<cas:proxySuccess> server responses.

=head3 new( doc =E<gt> $doc )

C<new()> creates an instance of an C<Authen::CAS::Client::Response::Success>
object.  C<$doc> is the response document.

=head2 Authen::CAS::Client::Response::AuthSuccess

Authen::CAS::Client::Response::AuthSuccess is a subclass of
C<Authen::CAS::Client::Response::Success> and is used when
validation succeeds.

=head3 new( user =E<gt> $user, iou =E<gt> $iou, proxies =E<gt> \@proxies, doc =E<gt> $doc )

C<new()> creates an instance of an C<Authen::CAS::Client::Response::AuthSuccess>
object.  C<$user> is the username received in the response.  C<$iou>
is the proxy granting ticket IOU, if present.  C<\@proxies> is the
list of proxies used during validation, if present.  C<$doc> is the
response document.

=head3 user()

C<user()> returns the user name that was contained in the server response.

=head3 iou()

C<iou()> returns the proxy granting ticket IOU, if it was present in the
server response.  Otherwise it is set to C<undef>.

=head3 proxies()

C<proxies()> returns the list of proxies present in the server response.  If
no proxies are found, an empty list is returned.  In scalar context an
array reference will be returned instead.

=head2 Authen::CAS::Client::Response::ProxySuccess

Authen::CAS::Client::Response::ProxySuccess is a subclass of
C<Authen::CAS::Client::Response::Success> and is used when a
C<cas:proxySuccess> response is received from the CAS server during
a proxy attempt.

=head3 new( proxy_ticket =E<gt> $proxy_ticket, doc =E<gt> $doc )

C<new()> creates an instance of an C<Authen::CAS::Client::Response::ProxySuccess>
object.  C<$proxy_ticket> is the proxy ticket received in the response.
C<$doc> is the response document.

=head3 proxy_ticket()

C<proxy_ticket()> returns the proxy ticket that was contained in the
server response.

=head1 BUGS

None are known at this time, but if you find one, please feel free to
submit a report to the author.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Authen::CAS::Client>

=back

=head1 LICENSE

This software is information.
It is subject only to local laws of physics.

=cut
