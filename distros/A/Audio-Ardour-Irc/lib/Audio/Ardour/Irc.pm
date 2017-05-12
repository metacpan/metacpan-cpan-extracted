package Audio::Ardour::Irc;

use 5.008008;
use strict;
use warnings;
use Carp;
use File::Spec;
use Net::LibLO;
use File::HomeDir;

our $VERSION = '0.20';

=head1 NAME

Audio::Ardour::Irc - Automate the Ardour DAW software.

=head1 SYNOPSIS

  use Audio::Ardour::Irc;
  my $ardour_controller = Audio::Ardour::Irc->new($url);
  $ardour_controller->sendOSCMessage($message);

  example messages (see http://ardour.org/osc_control for full list):

  $ardour_controller->sendOSCMessage('transport_play');
  $ardour_controller->sendOSCMessage('transport_stop');
  
  etc... 

=head1 DESCRIPTION

This module sends OSC messages to the Ardour DAW. 

NOTE: this is a direct replacement for Audio::Ardour::Control and
builds on Jonathan Stowe's original work.


=head2 METHODS

=over 2

=item new

Construct a new Audio::Ardour::Irc object. The only argument is the
URL of the Ardour OSC instance in the form C<osc.udp://<hostname>:<port>/>,
this is printed to STDERR by Ardour when the OSC is enabled.  For versions
of Ardour from 2.2 onwards the URL will be written to a file in the user
specific config directory and an attempt will be made to determine the URL
from that source, if it is not present and no URL has been specified as an
argument then this will croak.

=cut

sub new
{
   my ( $class, $url ) = @_;
   my $self = bless {}, $class;

   if( ! $self->url($url) )
   {
      croak "Cannot discover URL and no URL specified";
   }

   return $self;

}


=item sendOscMessage

Make sure you pass a valid OSC command...

=cut

sub sendOscMessage
{
   my ( $self ) = @_;
   my $message = '/ardour/' . $_[1];
   
   #print "$message\n";
   return $self->send($message, undef);
}


=back

=head2 INTERNAL METHODS

The below methods are used internally and might not be useful for
general use unless you are sub-classing or extending this module.

=over 

=item url

Get and/or set the URL to connect to the instance of Ardour we want to
control.

If the url is not specifiied and has not been previously set then 
discover_url() will be called. It will return undef if no URL can be
found.

=cut

sub url
{
   my ( $self, $url ) = @_;

   if ( defined $url )
   {
      $self->{_url} = $url;
   }

   if ( not exists $self->{_url} )
   {
      if ( $url = $self->discover_url() )
      {
         $self->{_url} = $url;
      }
   }

   return $self->{_url};
}

=item discover_url

Attempt to read the URL from the $HOME/.ardour2/osc_url file, returns undef
if the file doesn't exist.

This will not work for Ardour versions earlier than 2.2

=cut

sub discover_url
{
   my ( $self ) = @_;

   my $home = File::HomeDir->my_home();
   my $osc_url = File::Spec->catfile($home,'.ardour2','osc_url');

   my $url;
   if ( open URL, $osc_url )
   {
      chomp($url = <URL>);
   }
   return $url;
}

=item send

Send a request to the OSC host. The arguments are the OSC path and the
arguments for the call.

=cut

sub send
{
   my ( $self, $path, $argspec, $args ) = @_;
   $self->lo()->send($self->address, $path, $argspec, $args);
}

=item lo

Get and/or set the underlying L<Net::LibLO> object that we are using.

=cut

sub lo
{
   my ( $self, $lo ) = @_;

   if ( defined $lo )
   {
      $self->{_lo} = $lo;
   }

   if ( not exists $self->{_lo} )
   {
      $self->{_lo} = Net::LibLO->new();
   }

   return $self->{_lo};
}


=item address

Get and/or set the L<Net::LibLO::Address> object based on the URL of the
Ardour OSC instance that we are going to use. If the address has not previously
been set then a new object will be created.

=cut

sub address
{
   my ( $self, $address ) = @_;

   if ( defined $address )
   {
      $self->{_addr} = $address;
   }

   if ( not exists $self->{_addr} )
   {
      $self->{_addr} = Net::LibLO::Address->new($self->url());
   }

   return $self->{_addr};

}

=back

=head2 EXPORT

None.

=head1 BUGS AND SUPPORT

The OSC support in Ardour and this module should be considered experimental,
you almost certainly don't want to use this on any important Sessions without
thorough testing.

=head1 SEE ALSO

L<Net::LibLO>, Ardour documentation L<http://www.ardour.org>, 
OSC <http://opensoundcontrol.org/>

=head1 AUTHOR

Noel Darlow, E<lt>cpan@aperiplus.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Noel Darlow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
__END__

