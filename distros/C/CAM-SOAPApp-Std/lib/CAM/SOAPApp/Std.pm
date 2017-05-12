package CAM::SOAPApp::Std;

=head1 NAME

CAM::SOAPApp::Std - Clotho standard SOAP tools

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

Use this just as you would use CAM::SOAPApp.

=head1 DESCRIPTION

CAM::SOAPApp::Std adds Clotho conventions to CAM::SOAPApp.  This
includes an omnipresent requestID and auto-detection of
request/response wrappers.  Those wrappers are handy when working with
non-Perl SOAP implementations that can't support receiving unordered
arguments or returning multiple values, like Apache Axis for Java.

=cut

#--------------------------------#

require 5.005_62;
use strict;
use warnings;
use CAM::SOAPApp;

our @ISA = qw(CAM::SOAPApp);
our $VERSION = '1.03';

#--------------------------------#

=head1 METHODS

=over 4

=cut

#--------------------------------#

=item new ...

Adds auto-detection of a C<request> wrapper in the incoming data.

=cut

sub new
{
   my $pkg = shift;
   my $self = $pkg->SUPER::new(@_);

   my %args = $self->SUPER::getSOAPData();
   if ($args{request} && ref $args{request})
   {
      $self->{wrapresponse} = 1;
   }

   return $self;
}
#--------------------------------#

=item getSOAPData

Adds unwrapping of C<request> tag, if present.

=cut

sub getSOAPData
{
   my $self = shift;

   my %args = $self->SUPER::getSOAPData();
   if ($args{request} && ref $args{request})
   {
      %args = (%args, %{$args{request}});
   }
   return (%args);
}
#--------------------------------#

=item response KEY => VALUE, KEY => VALUE, ...

Adds an implicit C<requestID => $input{requestID}> to the parameter
list.  Also adds wrapping of response in a C<response> tag, if
applicable.

=cut

sub response
{
   my $self = shift;
   my $reqID = ($self->{wrapresponse} ?
                $self->{soapdata}->{request}->{requestID} :
                $self->{soapdata}->{requestID});
   my %response = (@_, requestID => $reqID);

   if ($self->{wrapresponse})
   {
      return $self->SUPER::response(response => \%response);
   }
   else
   {
      return $self->SUPER::response(%response);
   }
}
#--------------------------------#

=item error

=item error FAULTCODE

=item error FAULTCODE, FAULTSTRING

=item error FAULTCODE, FAULTSTRING, KEY => VALUE, KEY => VALUE, ...

Adds an implicit C<requestID => $input{requestID}> to the fault detail
parameter list.

=cut

sub error
{
   my $self = shift;
   my $code = shift;
   my $string = shift;
   my $reqID = (ref($self) ? 
                ($self->{wrapresponse} ?
                 $self->{soapdata}->{request}->{requestID} :
                 $self->{soapdata}->{requestID}) :
                undef);
   $self->SUPER::error($code, $string, @_,
                       ($reqID ? (requestID => $reqID) : ()));
}
#--------------------------------#

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media, I<cpan@clotho.com>

Primary developer: Chris Dolan
