##############################################################################
#
#  Data::Tools::Socket::Protocols perl module
#  Copyright (c) 2013-2023 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
#  Data::Tools::Socket::Protocols is ported from Decor's 
#  Decor::Shared::Net::Protocols: https://github.com/cade-vs/perl-decor
#
##############################################################################
package Data::Tools::Socket::Protocols;
use strict;
use Exporter;
use Carp;
use Data::Tools;
use Data::Tools::Socket;

our $VERSION = '1.41';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  socket_protocol_read_message
                  socket_protocol_write_message

                  socket_protocols_allow
                );

my %PROTOCOL_TYPES = (
                  'p' => {
                         'require' => 'Storable',
                         'pack'    => \&protocol_type_storable_pack, 
                         'unpack'  => \&protocol_type_storable_unpack,
                         },
                  'e' => {
                         'require' => 'Sereal',
                         'pack'    => \&protocol_type_sereal_pack, 
                         'unpack'  => \&protocol_type_sereal_unpack,
                         },
                  's' => {
                         'require' => 'Data::Stacker',
                         'pack'    => \&protocol_type_stacker_pack, 
                         'unpack'  => \&protocol_type_stacker_unpack,
                         },
                  'j' => {
                         'require' => 'JSON',
                         'pack'    => \&protocol_type_json_pack, 
                         'unpack'  => \&protocol_type_json_unpack,
                         },
                  'x' => {
                         'require' => 'XML::Simple',
                         'pack'    => \&protocol_type_xml_pack, 
                         'unpack'  => \&protocol_type_xml_unpack,
                         },
                  'h' => {
                         'require' => undef,
                         'pack'    => \&protocol_type_hash_pack, 
                         'unpack'  => \&protocol_type_hash_unpack,
                         },
                  );

my %PROTOCOL_ALLOW = map { $_ => 1 } keys %PROTOCOL_TYPES;

sub socket_protocol_read_message
{
  my $socket  = shift;
  my $timeout = shift;
  
  my ( $data, $data_read_len ) = socket_read_message( $socket, $timeout );
  if( ! defined $data )
    {
    return wantarray ? ( undef, undef, $data_read_len == 0 ? 'E_EOF' : 'E_SOCKET' ) : undef;
    }

  my $ptype = substr( $data, 0, 1 );
  confess "unknown or forbidden PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', keys %PROTOCOL_ALLOW ) . "]" unless exists $PROTOCOL_ALLOW{ $ptype };
  my $proto = $PROTOCOL_TYPES{ $ptype };

  my $hr = $proto->{ 'unpack' }->( substr( $data, 1 ) );
  confess "invalid data received from socket stream, expected HASH reference" unless ref( $hr ) eq 'HASH';

  return wantarray ? ( $hr, $ptype, 'OK' ) : $hr;
}

sub socket_protocol_write_message
{
  my $socket  = shift;
  my $ptype   = shift;
  my $hr      = shift;
  my $timeout = shift;
  
  confess "unknown or forbidden PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', keys %PROTOCOL_ALLOW ) . "]" unless exists $PROTOCOL_ALLOW{ $ptype };
  my $proto = $PROTOCOL_TYPES{ $ptype };
  
  confess "expected HASH reference at arg #3" unless ref( $hr ) eq 'HASH';

  my $data = $ptype . $proto->{ 'pack' }->( $hr );
  
  return socket_write_message( $socket, $data, $timeout );
}

#-----------------------------------------------------------------------------

sub socket_protocols_allow
{
  %PROTOCOL_ALLOW = ();
  my @p = split //, join '', @_;
  for my $ptype ( @p )
    {
    if( $ptype eq '*' )
      {
      %PROTOCOL_ALLOW = map { $_ => 1 } keys %PROTOCOL_TYPES;
      return;
      }
    confess "unknown or forbidden PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', keys %PROTOCOL_ALLOW ) . "]" unless exists $PROTOCOL_ALLOW{ $ptype };
    $PROTOCOL_ALLOW{ $ptype }++;
    }
}

my %PROTOCOL_LOADED;
sub load_protocol
{
  my $ptype = shift;
  return if exists $PROTOCOL_LOADED{ $ptype };
  confess "unknown or forbidden PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', keys %PROTOCOL_ALLOW ) . "]" unless exists $PROTOCOL_ALLOW{ $ptype };
  
  my $req = $PROTOCOL_TYPES{ $ptype }{ 'require' };
  if( $req )
    {
    eval { my $fn = perl_package_to_file( $req ); require $fn; };
    confess "cannot load PROTOCOL_TYPE [$ptype] error: $@" if $@;
    }  
  $PROTOCOL_LOADED{ $ptype }++;
  return 1;
}

#-----------------------------------------------------------------------------

sub protocol_type_storable_pack
{
  load_protocol( 'p' );
  return Storable::nfreeze( shift );
}

sub protocol_type_storable_unpack
{
  load_protocol( 'p' );
  return Storable::thaw( shift );
}

sub protocol_type_sereal_pack
{
  load_protocol( 'e' );
  return Sereal::encode_sereal( shift );
}

sub protocol_type_sereal_unpack
{
  load_protocol( 'e' );
  return Sereal::decode_sereal( shift );
}

sub protocol_type_stacker_pack
{
  load_protocol( 's' );
  return Data::Stacker::stack_data( shift );
}

sub protocol_type_stacker_unpack
{
  load_protocol( 's' );
  return Data::Stacker::unstack_data( shift );
}

sub protocol_type_json_pack
{
  load_protocol( 'j' );
  return JSON::encode_json( shift );
}

sub protocol_type_json_unpack
{
  load_protocol( 'j' );
  return JSON::decode_json( shift );
}

sub protocol_type_xml_pack
{
  load_protocol( 'x' );   
  return XML::Simple::XMLout( shift );
}

sub protocol_type_xml_unpack
{
  load_protocol( 'x' );
  return XML::Simple::XMLin( shift );
}

sub protocol_type_hash_pack
{
  load_protocol( 'h' );
  return hash2str( shift );
}

sub protocol_type_hash_unpack
{
  load_protocol( 'h' );
  return str2hash( shift );
}

##############################################################################
1;
