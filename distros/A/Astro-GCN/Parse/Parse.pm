package Astro::GCN::Parse;

=head1 NAME

GCN::Packet::Parse - module which parses valid GCN binary messages

=head1 SYNOPSIS

   $message = new Astro::GCN::Parse( Packet => $packet );

=head1 DESCRIPTION

The module parses incoming GCN binary packet and parses it, it will 
correct parse TYPE_IM_ALIVE and all (most?) SWIFT related packets.
   
=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Time::localtime;
use Data::Dumper;
use Carp;

use Astro::GCN::Constants qw(:packet_types);
use Astro::GCN::Util;
use Astro::GCN::Util::SWIFT;

'$Revision: 1.1.1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Parse.pm,v 1.1.1.1 2005/05/03 19:23:00 voevent Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $message = new Astro::GCN::Parse( Packet => $packet );

returns a reference to an message object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { BUFFER  => undef,
                      MESSAGE => [],
                      TYPE    => undef  }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}



# A C C E S S O R   M E T H O D S --------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<type>

Return the packet type

  $pkt_type = $message->type();

=cut

sub type {
  my $self = shift;
  return $self->{TYPE};
}

=item B<serial_number>

Return the packet serial number

  $pkt_sernum = $message->serial_number();

=cut

sub serial_number {
  my $self = shift;
  return $self->{MESSAGE}[1];
}


=item B<hop_count>

Return the packet hop count which is incremented by each node

  $pkt_hop_cnt = $message->hop_count();

=cut

sub hop_count {
  my $self = shift;
  return $self->{MESSAGE}[2];
}

=item B<gcn_sod>

Return the time (seconds of day) when the packet was sent from the GCN.

  $sod = $message->gcn_sod();

=cut

sub gcn_sod {
  my $self = shift;
  return ( $self->{MESSAGE}[3] / 100.0 );
}

# S W I F T   R E L A T E D   M E T H O D S ---------------------------------

=item B<is_swift>

Returns true if the packet originates from SWIFT, or undef if not

  if ( defined $message->is_swift() ) {
     .
     .
     .
  }

=cut

sub is_swift {
  my $self = shift;
  
  if ( $self->type() >= 60 && $self->type <= 82 ) {
     return 1;
  } else {
     return undef;
  }      
}

=item B<trigger_num>

Return the trigger number (SWIFT packets only)

  $trigger_num = $message->trigger_num();

=cut

sub trigger_num {
  my $self = shift;
  
  return undef unless $self->is_swift();
  
  my ( $trig_num, $obs_num ) = 
    Astro::GCN::Util::SWIFT::convert_trig_obs_num( $self->{MESSAGE}[4] );
  return $trig_num;
     
}

=item B<obs_num>

Return the obs number (SWIFT packets only)

  $obs_num = $message->obs_num();

=cut

sub obs_num {
  my $self = shift;
  return undef unless $self->is_swift();

  my ( $trig_num, $obs_num ) = 
    Astro::GCN::Util::SWIFT::convert_trig_obs_num( $self->{MESSAGE}[4] );
  return $obs_num;
     
}

=item B<tjd>

Return the truncated Julian Date of the observation. The precise 
defintion of this varies depending on the type of the original packet. 


  $julian_date = $message->tjd();

For now this method will only return a value for SWIFT packets.

=cut

sub tjd {
  my $self = shift;
  return undef unless $self->is_swift();
  if ( $self->type() >= 74 && $self->type <= 75 ) {
     return undef;
  }   
  
  return $self->{MESSAGE}[5];
     
}

=item B<data_sod>

Return the time (seconds of day) when the data originated at the
instrument. The precise defintion of this varies depending on the 
type of the original packet.

  $sod = $message->data_sod();
  
For now this method will only return a value for SWIFT packets.

=cut

sub data_sod {
  my $self = shift;
  
  return undef unless $self->is_swift();
  if ( $self->type() >= 74 && $self->type <= 75 ) {
     return undef;
  }   
  return ( $self->{MESSAGE}[6] / 100.0 );
}

=item B<ra>

Return the RA in "hh mm ss.ss" format. The precise defintion of this 
varies depending on the type of the original packet.

  $ra = $message->ra();

For now this method will only return a value for SWIFT packets.

=cut

sub ra {
  my $self = shift;
  return undef unless $self->is_swift();
  if ( $self->type() == 60 || $self->type == 62 ||
       ( $self->type() >= 74 && $self->type <= 75 ) ) {
     return undef;
  }   
  
  my $ra = Astro::GCN::Util::convert_ra_to_sextuplets( $self->{MESSAGE}[7] );
  return $ra;  
     
}

=item B<dec>

Return the Declination in "+dd mm ss.ss" format. The precise defintion 
of this varies depending on the type of the original packet.

  $dec = $message->dec();

For now this method will only return a value for SWIFT packets.

=cut

sub dec {
  my $self = shift;
  return undef unless $self->is_swift();
  if ( $self->type() == 60 || $self->type == 62 ||
       ( $self->type() >= 74 && $self->type <= 75 ) ) {
     return undef;
  }   
  
  my $dec = Astro::GCN::Util::convert_dec_to_sextuplets( $self->{MESSAGE}[8] );
  return $dec;  
     
}

=item B<burst_error>

Return the error in RA & Declination in arc minutes. The precise 
defintion of the original values of RA & Declination will vary depending 
on the type of the original packet.

  $error = $message->burst_error();

For now this method will only return a value for the relevant SWIFT packets,
these being types 61, 67, 81 and 84.

=cut

sub burst_error {
  my $self = shift;
  return undef unless $self->is_swift();
  unless ( $self->type() == 61 || $self->type == 67 ||
           $self->type() == 81 || $self->type == 84 ) {
     return undef;
  }   
  
  my $error = 
    Astro::GCN::Util::convert_burst_error_to_arcmin ( $self->{MESSAGE}[11] );
    
  return $error;  
     
}


=item B<ra_degrees>

Return the RA in degrees. The precise defintion of this 
varies depending on the type of the original packet.

  $ra = $message->ra_degrees();

For now this method will only return a value for SWIFT packets.

=cut

sub ra_degrees {
  my $self = shift;
  return undef unless $self->is_swift();
  if ( $self->type() == 60 || $self->type == 62 ||
       ( $self->type() >= 74 && $self->type <= 75 ) ) {
     return undef;
  }   
  
  my $ra = Astro::GCN::Util::convert_ra_to_degrees( $self->{MESSAGE}[7] );
  return $ra;  
     
}

=item B<dec_degrees>

Return the Declination in degrees. The precise defintion 
of this varies depending on the type of the original packet.

  $dec = $message->dec_degrees();

For now this method will only return a value for SWIFT packets.

=cut

sub dec_degrees {
  my $self = shift;
  return undef unless $self->is_swift();
  if ( $self->type() == 60 || $self->type == 62 ||
       ( $self->type() >= 74 && $self->type <= 75 ) ) {
     return undef;
  }   
  
  my $dec = Astro::GCN::Util::convert_dec_to_degrees( $self->{MESSAGE}[8] );
  return $dec;  
     
}

=item B<burst_error_degrees>

Return the error in RA & Declination in degrees. The precise 
defintion of the original values of RA & Declination will vary depending 
on the type of the original packet.

  $error = $message->burst_error_degrees();

For now this method will only return a value for the relevant SWIFT packets,
these being types 61, 67, 81 and 84.

=cut

sub burst_error_degrees {
  my $self = shift;
  return undef unless $self->is_swift();
  unless ( $self->type() == 61 || $self->type == 67 ||
           $self->type() == 81 || $self->type == 84 ) {
     return undef;
  }   
  
  my $error = 
    Astro::GCN::Util::convert_burst_error_to_degrees ( $self->{MESSAGE}[11] );
    
  return $error;  
     
}

=item B<solution_status>

Return the type of solution for relevant BAT messages.

  $soln_status = $message->solution_status();

This method will only return a value for the relevant SWIFT packets,
these being types 61, 62, 82 and 84.

=cut

sub solution_status {
  my $self = shift;
  return undef unless $self->is_swift();
  unless ( $self->type() == 61 || $self->type == 62 ||
           $self->type() == 82 || $self->type == 84 ) {
     return undef;
  }   
  
  my %soln_status = 
    Astro::GCN::Util::SWIFT::convert_soln_status ( $self->{MESSAGE}[18] );
    
  return %soln_status;  
     
}

=item B<bat_ipeak>

Return the height of the peak in the sky-image plane in counts

  $error = $message->burst_error();

This is valid for SWIFT BAT only (packet types 61 or 82)

=cut

sub bat_ipeak {
  my $self = shift;
  return undef unless $self->is_swift();
  unless ( $self->type() == 61 || $self->type == 82 ) {
     return undef;
  }   
  
  return $self->{MESSAGE}[10];
         
}


=item B<uvot_mag>

Return the magnitude of the SWIFT UVOT pointing

  $error = $message->uvot_mag();

This is valid for SWIFT UVOT only (packet types 81)

=cut

sub uvot_mag {
  my $self = shift;
  unless ( $self->type() == 81 ) {
     return undef;
  }   
  
  return ( $self->{MESSAGE}[9] / 100.0 );
         
}

# C O N F I G U R E ----------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $message->configure( %options );

Does nothing if the hash is not supplied. This is called directly from
the constructor during object creation

=cut

sub configure {
  my $self = shift;

  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Packet / ) {
      my $method = lc($key);
         # normal configuration methods (if needed)
         $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# M E T H O D S -------------------------------------------------------------

=item B<packet>

Read the binary packet and convert,

   $message->packet( $binary_packet );

takes the GCN native binary packet and converts to local format, then
parses known packet types and makes the information available via the
accessor methods.

=cut

sub packet {
  my $self = shift;
  $self->{BUFFER} = shift;
  
  # parse the document using private methods.
  push @{$self->{MESSAGE}}, unpack( "N40", $self->{BUFFER} );
  $self->{TYPE} = $self->{MESSAGE}[0];

}


# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2005 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
