package AmbientOrb::Serial;



=head1 NAME

AmbientOrb::Serial - Perl module for interfacing with your Orb via serial port.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module allows you to do communicate with your ambient orb via serial port.  
Please see the reference manual at L<http://www.ambientdevices.com/developer/> 
if you want to delve a little deeper.  The ambient orb home page can be found
at L<http://www.ambientdevices.com/cat/index.html>.

Tested only on a Win32 system, but it should work fine for a non-Windows host; just
pass the constructor the /dev path of the port.

    use AmbientOrb::Serial;

    my $orb = AmbientOrb::Serial->new( { port_name => COM1 } );
    $orb->connect() or die "unable to connect to orb!";
    $orb->color( ORB_RED );  #turn it red
    $orb->pulse( ORB_RED, ORB_SLOW ); #pulse it slow
    $orb->pulse( ORB_GREEN, ORB_FAST ); #pulse it fast
    ...

=cut

=head1 EXPORT
 
By default the constants for colors and animations are exported.

Constants are exported for the different colors and animations. Note that I'm mucking around directly with the symbol
table and exporting these constants to main::ORB_RED, for example.  I know.  I'm bad.  I'm sorry. 

For example:

    use AmbientOrb::Serial;
    print ORB_RED;  #prints 'RED'

=cut




=head1 AUTHOR

Lyle Hayhurst, C<< <sozin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ambientorb-serial at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AmbientOrb-Serial>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

=over 4

=item * Need to add support for manual setting of RGB

=item * Need to add support for getting orb diagnostics.

=item * Probably need to have the thing pull out of serial mode when the port is disconnected.

=item * And further on, create AmbientOrb::Web that supports the same feature set, except via the web interface.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AmbientOrb::Serial

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AmbientOrb-Serial>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AmbientOrb-Serial>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AmbientOrb-Serial>

=item * Search CPAN

L<http://search.cpan.org/dist/AmbientOrb-Serial>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Lyle Hayhurst, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use warnings;
use integer;
use Carp;
use vars qw(%color_map %animation_map $OS_win);

sub export_constants
{
    my ( $hash, $caller ) = @_;
    foreach my $name ( keys %$hash )
    {
	my $value = $hash->{$name};
 	*{$name} = sub () { $value };
 	push @{$caller.'::EXPORT'}, $name;
    }
}

BEGIN {

    #determine the operating system
    $OS_win = ($^O eq "MSWin32") ? 1 : 0;
    if ($OS_win) {
	eval "use Win32::SerialPort qw( :STAT 0.19 )";
	die "$@\n" if ($@);
    }
    else {
	eval "use Device::SerialPort";
	die "$@\n" if ($@);
    }

    #build the color and animation maps
    %color_map = ( ORB_RED => 0,
		   ORB_ORANGE => 3,
		   ORB_YELLOW => 6,
		   ORB_GREEN => 12,
		   ORB_AQUA => 16,
		   ORB_CYAN => 18,
		   ORB_BLUE => 24,
		   ORB_VIOLET => 27,
		   ORB_PURPLE => 28,
		   ORB_MAGENTA => 30,
		   ORB_WHITE => 36 );
    
    %animation_map = ( ORB_NONE => 0,
		       ORB_VERY_SLOW => 1,
		       ORB_SLOW => 2,
		       ORB_MEDIUM_SLOW => 3,
		       ORB_MEDIUM => 4,
		       ORB_MEDIUM_FAST => 5,
		       ORB_FAST => 6,
		       ORB_VERY_FAST => 7,
		       ORB_CRESCENDO => 8,
		       ORB_HEARTBEAT => 9 );

    export_constants( \%color_map, caller );
    export_constants( \%animation_map, caller );
}

use strict;    
use base qw(Class::Accessor);
AmbientOrb::Serial->mk_accessors( qw/serial_port port_name/ );

=head1 FUNCTIONS

#public methods

=head2 connect
The connect method will attempt to establish a serial port connection with the orb.

Note that, as per the spec, the first thing it does is transmit a GT message to the orb.
This will tell it to ignore wireless input and use the serial port input instead.

If all goes well, it returns a 1, else a 0.

=cut

sub connect {
    my ( $self ) = @_;
    my $port = create_serial_port( $self->port_name );
    $self->serial_port( $port );

    #tell the orb to ignore the pager data
    my $result = $self->send( pack("a3", "~GT" ) );
    if ( not $result =~ "G+" ) {
	return 0;
    }
    return 1;
}

=head2 color
The color method instructs the orb to change its color.  

It takes a single argument -- the color to turn it.

I'm actually lying here -- it can take an optional third argument, the pulse frequency.
But if you want to pulse the orb you might as well use the pulse() function, if only
for code readability.

=cut

sub color
{
    my ( $self, $color, $anim ) = @_;
    $anim ||= 0;

    my $message = $self->color_to_ascii( $color, $anim );

    my $result = $self->send( $message );
    if ( not $result =~ "A+" )
    {
	return 0;
    }
    return 1;
       
}

=head2 pulse
The pulse method instructs the orb to change its color and pulse.

It takes a two arguments -- the color to turn to, and the pulse frequency.

=cut

sub pulse
{
    my ( $self, $color, $anim ) = @_;
    return $self->color( $color, $anim );
}

#private methods

sub create_serial_port
{
    my ( $port_name ) = @_;
    my $serial_port;

    if ( $OS_win )
    {
	$serial_port = Win32::SerialPort->new( $port_name );
    }
    else
    {
	$serial_port = Device::SerialPort->new( $port_name );
    }
    
    croak "unable to connect to serial port $port_name: $^E"
	unless $serial_port;

    #as per the specification
    $serial_port->baudrate(19200);
    $serial_port->databits(8);
    $serial_port->stopbits(1);
    $serial_port->parity("none");
    $serial_port->handshake("none");
    return $serial_port;
}
	
	

sub send {
    my ( $self, $message ) = @_;
    $self->serial_port->write( $message );
    my $result;

    #the docs say that you have to poll a lot to get the 
    #correct result back.  there is no doubt a better way 
    #to do this, but 1000 seems to be a nice magic number 
    for ( 1 .. 1000 )
    {
	$result = $self->serial_port->input;
	if ( $result =~ /\w+/ )
	{
	    last;
	}
    }
    return $result;
}
	
sub color_to_ascii
{
    my ( $self, $color, $anim ) = @_;

    my $colorval = $color_map{$color};

    croak "unknown color $colorval!" unless defined $colorval;

    $anim = $animation_map{$anim} if defined $anim;
    $anim ||= 0;

    my $firstByte   = ( ($colorval + ( 37 * $anim)) / 94 ) + 32;
    my $secondByte  = ( ($colorval + ( 37 * $anim)) % 94 ) + 32 ;
		      
    $secondByte = sprintf("%c", $secondByte);
    $firstByte  = sprintf("%c", $firstByte );
    my $packme  = "~A" . $firstByte . $secondByte;
    my $message = pack("a4", $packme);
    
    return $message;
}

sub DESTROY
{
    my ( $self ) = @_;
    if ( defined $self->serial_port )
    {
	$self->serial_port->close() || warn "unable to close serial port!\n";
	undef $self->serial_port;
    }
}

1; # End of AmbientOrb::Serial
