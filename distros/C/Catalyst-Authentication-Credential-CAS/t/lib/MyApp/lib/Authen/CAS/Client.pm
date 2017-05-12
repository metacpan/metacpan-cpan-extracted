package Authen::CAS::Client;

use namespace::autoclean;
use Authen::CAS::Client::Response;
use Moose;
use URI;


has url => ( is => 'rw', isa => 'Str' );


sub BUILDARGS { { url => @_[1..$#_] } }

sub login_url { $_[0]->url }

sub validate { shift->_validate( @_ ) }

sub service_validate { shift->_validate( @_ ) }

sub _validate {
  my ( $self, $service, $ticket ) = @_;

  return Authen::CAS::Client::Response::AuthSuccess->new( user => $1 )
    if $ticket =~ /^ST-USER:(.*)\z/;

  return Authen::CAS::Client::Response::AuthFailure->new( code => 'FAIL', message => 'Failure is always an option' )
    if $ticket =~ /^ST-FAIL\z/;

  return Authen::CAS::Client::Response::Error->new( error => 'CPAN, we have a problem' );
}


1
__END__
