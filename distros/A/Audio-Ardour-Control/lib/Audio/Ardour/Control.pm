package Audio::Ardour::Control;

use 5.008008;
use strict;
use warnings;
use Carp;
use File::Spec;
use Net::LibLO;
use File::HomeDir;

our $VERSION = '0.20';

=head1 NAME

Audio::Ardour::Control - Automate the Ardour DAW software.

=head1 SYNOPSIS

  use Audio::Ardour::Control;

  my $ardcontrol = Audio::Ardour::Control->new($url);

  $ardcontrol->rec_enable_toggle();
  $ardcontrol->transport_play();
  # do stuff
  $ardcontrol->transport_stop();

=head1 DESCRIPTION

Ardour is an open source digital audio workstation software (DAW) for
Unix-like systems, it provides an interface to allow it to be controlled
using the Open Sound Control (OSC) protocol. This module uses OSC to
enable control of Ardour from a Perl program.

The methods below represent all of the actions exposed by Ardour via OSC,
for more detail on what they actually do you probably want to refer to the
Ardour documentation.

=head2 METHODS

=over 2

=item new

Construct a new Audio::Ardour::Control object. The only argument is the
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


=item add_marker

Adds a new location marker at the current location of the playhead.

=cut

sub add_marker
{
   my ( $self ) = @_;

   $self->send('/ardour/add_marker', undef);
}


=item loop_toggle

This toggles the effect of the loop range, if loop is on then transport_play
will loop over the defined loop range.

=cut

sub loop_toggle
{
   my ( $self ) = @_;

   $self->send('/ardour/loop_toggle', undef);
}


=item goto_start

Reposition the playhead at the start of the tracks.

=cut

sub goto_start
{
   my ( $self ) = @_;

   $self->send('/ardour/goto_start', undef);
}


=item goto_end

Reposition the playhead at the end of the session - (i.e. the "End" marker)

=cut

sub goto_end
{
   my ( $self ) = @_;

   $self->send('/ardour/goto_end', undef);
}


=item rewind

Roll the transport backward at twice the standard transport speed.

=cut

sub rewind
{
   my ( $self ) = @_;

   $self->send('/ardour/rewind', undef);
}


=item ffwd

Roll the transport forward at twice the standard transport speed.

=cut

sub ffwd
{
   my ( $self ) = @_;

   $self->send('/ardour/ffwd', undef);
}


=item transport_stop

Stop the current motion of the transport.

=cut

sub transport_stop
{
   my ( $self ) = @_;

   $self->send('/ardour/transport_stop', undef);
}


=item transport_play

Start playing.

=cut

sub transport_play
{
   my ( $self ) = @_;

   $self->send('/ardour/transport_play', undef);
}


=item set_transport_speed

Set the transport speed for use by other operations. The argument is a 
floating point number, where 0 is stopped and 1 is normal speed.

=cut

sub set_transport_speed
{
   my ( $self , $arg ) = @_;

   $self->send('/ardour/set_transport_speed','f', $arg);
}


=item save_state

Cause the session to be saved.

=cut

sub save_state
{
   my ( $self ) = @_;

   $self->send('/ardour/save_state', undef);
}


=item prev_marker

Move the playhead to the previous location marker.

=cut

sub prev_marker
{
   my ( $self ) = @_;

   $self->send('/ardour/prev_marker', undef);
}


=item next_marker

Move the playhead to the next location marker.

=cut

sub next_marker
{
   my ( $self ) = @_;

   $self->send('/ardour/next_marker', undef);
}


=item undo

Undo the last action.

=cut

sub undo
{
   my ( $self ) = @_;

   $self->send('/ardour/undo', undef);
}


=item redo

Repeat the last action.

=cut

sub redo
{
   my ( $self ) = @_;

   $self->send('/ardour/redo', undef);
}


=item toggle_punch_in

Switch the punch in point on or off.

=cut

sub toggle_punch_in
{
   my ( $self ) = @_;

   $self->send('/ardour/toggle_punch_in', undef);
}


=item toggle_punch_out

Switch the punch out point on or off.

=cut

sub toggle_punch_out
{
   my ( $self ) = @_;

   $self->send('/ardour/toggle_punch_out', undef);
}


=item rec_enable_toggle

Toggle the global record arming.

=cut

sub rec_enable_toggle
{
   my ( $self ) = @_;

   $self->send('/ardour/rec_enable_toggle', undef);
}


=item toggle_all_rec_enables

Toggle the track record enables. The track enables will not turn *off*
unless global record arming is set (i.e. the big record button is highlighted.)

=cut

sub toggle_all_rec_enables
{
   my ( $self ) = @_;

   $self->send('/ardour/toggle_all_rec_enables', undef);
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

Some of the control methods might not work in the version of Ardour that
you are using.

The OSC support in Ardour and this module should be considered experimental,
you almost certainly don't want to use this on any important Sessions without
thorough testing.

Please provider full details of the version of Ardour you are using if you
want to report a bug.  Also please feel free to tell me which bits *do*
work along with the version of Ardour :-)

=head1 SEE ALSO

L<Net::LibLO>, Ardour documentation L<http://www.ardour.org>, 
OSC <http://opensoundcontrol.org/>

=head1 AUTHOR

Jonathan Stowe, E<lt>jns@gellyfish.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Jonathan Stowe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
__END__

