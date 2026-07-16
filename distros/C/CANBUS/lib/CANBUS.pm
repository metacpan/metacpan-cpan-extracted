package CANBUS;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CANBUS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('CANBUS', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CANBUS - Perl extension for sending and receiving CANBUS messages using
the Linux CANBUS driver.

=head1 SYNOPSIS

  use CANBUS;
  CANBUS::setup('can0') ;
  CANBUS::send($id,\@data) ;
  @data = CANBUS::receive() ; 
 
=head1 DESCRIPTION

  CANBUS::setup($interface) ;

Open a socket, bind it to the interface

May require that the interface is brought up first, e.g.
  sudo ip link set can0 type can bitrate 250000
  sudo ip link set can0 up

  CANBUS::send($id,\@data) ;

Send data from an array passed by reference to a named ID, using the
configured interface

  @data = CANBUS::receive() ;

Read data from the configured interface and place it on the stack. There may be a variable
number of data words.

   CANBUS::teardown() ;

Close the socket for the configured interface.


=head2 EXAMPLE

 my $if = 'can0' ;
 my $id = 1 ;
 CANBUS::setup($if) ;           # open interface
 my @data = (0x09,0x81,1,0,0) ; # get battery voltage
 CANBUS::send($id,\@data) ;     # send the message
 while (1) {
   @data = CANBUS::receive() ; 
   if ($data[0] == 0x500) { last ; }  # ignore broadcasts, wait for a reply
 }
 CANBUS::teardown() ;


=head2 EXPORT

None by default.



=head1 SEE ALSO

The can-utils package, cansend, candump

=head1 AUTHOR

Andrew Daviel, E<lt>advax@daviel.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Andrew Daviel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
