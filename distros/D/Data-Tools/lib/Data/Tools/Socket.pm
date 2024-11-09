##############################################################################
#
#  Data::Tools::Socket perl module
#  Copyright (c) 2013-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
##############################################################################
package Data::Tools::Socket;
use strict;
use Exporter;
use Time::HiRes qw( time );

our $VERSION = '1.45';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  socket_read
                  socket_write
                  socket_print

                  socket_read_message
                  socket_write_message
                  
                  socket_can_write
                  socket_can_read
                );

##############################################################################

sub socket_read
{
   my $sock    = shift;
   my $data    = shift;
   my $readlen = shift;
   my $timeout = shift || undef;
   
   my $stime = time();
   $$data = undef;

   my $rlen = $readlen;
#print STDERR "SOCKET_READ: rlen [$rlen]\n";
   while( $rlen > 0 )
     {
     return undef if ! socket_can_read( $sock, $timeout ) or ( $timeout > 0 and time() - $stime > $timeout );
     
     my $part;
     my $plen = $sock->sysread( $part, $rlen );
     
     return undef if $plen <= 0;
     
     $$data .= $part;
     $rlen -= $plen;
#print STDERR "SOCKET_READ: part [$part] [$plen] [$rlen]\n";
     }

#print STDERR "SOCKET_READ: incoming data [$$data]\n";
   
  return $readlen - $rlen;
}

sub socket_write
{
   my $sock     = shift;
   my $data     = shift;
   my $writelen = shift;
   my $timeout  = shift || undef;
   
   my $stime = time();

#print STDERR "SOCKET_WRITE: outgoing data [$data]\n";
   my $wpos = 0;
   while( $wpos < $writelen )
     {
     return undef if ! socket_can_write( $sock, $timeout ) or ( $timeout > 0 and time() - $stime > $timeout );
 
     my $part;
     my $plen = $sock->syswrite( $data, $writelen - $wpos, $wpos );
#print STDERR "SOCKET_WRITE: part [$plen]\n";
     
     return undef if $plen <= 0;
     
     $wpos += $plen;
     }
   
#print STDERR "SOCKET_WRITE: part [$wpos] == writelen [$writelen]\n";
  return $wpos;
}

sub socket_print
{
   my $sock     = shift;
   my $data     = shift;
   my $timeout  = shift || undef;
   
   return socket_write( $sock, $data, length( $data ), $timeout );
}

##############################################################################

sub socket_read_message
{
  my $sock    = shift;
  my $timeout = shift;
   
  my $data_len_N32;
  my $rc_data_len = socket_read( $sock, \$data_len_N32, 4, $timeout );
  if( $rc_data_len == 0 )
    {
    # end of comms
    return undef;
    }
  my $data_len = unpack( 'N', $data_len_N32 );
  if( $rc_data_len != 4 or $data_len < 0 or $data_len >= 2**32 )
    {
    # ivalid length
    return undef;
    }
  if( $data_len == 0 )
    {
    return "";
    }

  my $read_data;
  my $res_data_len = socket_read( $sock, \$read_data, $data_len );
  if( $res_data_len != $data_len )
    {
    # invalid data len received
    return wantarray ? ( undef, $res_data_len ) : undef;
    }
  
  return wantarray ? ( $read_data, $res_data_len ) : $res_data_len;
}

sub socket_write_message
{
  my $sock    = shift;
  my $data    = shift;
  my $timeout = shift;
  
  # FIXME: utf?
  my $data_len = length( $data );
  my $res_data_len = socket_write( $sock, pack( 'N', $data_len ) . $data, 4 + $data_len, $timeout );
  if( $res_data_len != 4 + $data_len )
    {
    # invalid data len sent
    return undef;
    }

  return 1;
}

##############################################################################

sub socket_can_write
{
  my $sock    = shift;
  my $timeout = shift;

  my $win;
  vec( $win, fileno( $sock ), 1 ) = 1;
  return select( undef, $win, undef, $timeout ) > 0;
}

sub socket_can_read
{
  my $sock    = shift;
  my $timeout = shift;

  my $rin;
  vec( $rin, fileno( $sock ), 1 ) = 1;
  return select( $rin, undef, undef, $timeout ) > 0;
}

##############################################################################

=pod


=head1 NAME

  Data::Tools::Socket provides set of socket I/O functions.

=head1 SYNOPSIS

  use Data::Tools::Socket qw( :all );  # import all functions
  use Data::Tools::Socket;             # the same as :all :) 
  use Data::Tools::Socket qw( :none ); # do not import anything, use full package names

  # --------------------------------------------------------------------------

  my $read_res_len  = socket_read(  $socket, $data_ref, $length, $timeout );
  my $write_res_len = socket_write( $socket, $data,     $length, $timeout );
  my $write_res_len = socket_print( $socket, $data, $timeout );

  # --------------------------------------------------------------------------

  my $read_data = socket_read_message(  $socket, $timeout );
  my $write_res = socket_write_message( $socket, $data, $timeout );

  # --------------------------------------------------------------------------

=head1 FUNCTIONS

=head2 socket_read(  $socket, $data_ref, $length, $timeout )

Reads $length sized data from the $socket and store it to $data_ref scalar 
reference.

Returns read length (can be shorter than requested $length);

$timeout is optional, it is in seconds and can be less than 1 second.

=head2 socket_write( $socket, $data,     $length, $timeout )

Writes $length sized data from $data scalar to the $socket.

Returns write length (can be shorter than requested $length);

$timeout is optional, it is in seconds and can be less than 1 second.

=head2 socket_print( $socket, $data, $timeout )

Same as socket_write() but calculates requested length from the $data scalar.

$timeout is optional, it is in seconds and can be less than 1 second.

=head2 socket_read_message(  $socket, $timeout )

Reads 32bit network-order integer, which then is used as data size to be read
from the socket (i.e. message = 32bit-integer + data ).

Returns read data or undef for message or network error.

$timeout is optional, it is in seconds and can be less than 1 second.

=head2 socket_write_message( $socket, $data, $timeout )

Writes 32bit network-order integer, which is the size of the given $data to be
written to the $socket and then writes the data 
(i.e. message = 32bit-integer + data ).

Returns 1 on success or undef for message or network error.

$timeout is optional, it is in seconds and can be less than 1 second.

=head1 TODO

  * more docs

=head1 REQUIRED MODULES

Data::Tools::Socket uses:

  * IO::Select
  * Time::HiRes

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools.git
  
  git clone git://github.com/cade-vs/perl-data-tools.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  


=cut

##############################################################################
1;
###EOF########################################################################

