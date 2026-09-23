##############################################################################
#
#  Data::Tools::Socket::Protocols perl module
#  Copyright (c) 2013-2024 Vladi Belperchinov-Shabanski "Cade"
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

our $VERSION = '1.52';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  socket_protocol_read_message
                  socket_protocol_write_message

                  socket_protocols_allow
                );

my %PROTOCOL_TYPES = (
                  'b' => {
                         # binary. does not require anything, pack/unpack are essentially noops
                         },
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
                  'H' => {
                         'require' => undef,
                         'pack'    => \&protocol_type_hash_url_pack,
                         'unpack'  => \&protocol_type_hash_url_unpack,
                         },
                  );

my %PROTOCOL_ALLOW = map { $_ => 1 } keys %PROTOCOL_TYPES;

sub socket_protocol_read_message
{
  my $socket  = shift;
  my $timeout = shift;
  my $opt     = shift || {};

  my ( $data, $data_read_len, $error ) = socket_read_message( $socket, $timeout );

  if( $error )
    {
    # incoming length is unknown or socket error
    return wantarray ? ( undef, undef, $error ) : undef;
    }

  return wantarray ? ( undef, undef, 'E_EMPTY' ) : undef if $data_read_len == 0;

  my $ptype = substr( $data, 0, 1 );

  return wantarray ? ( undef, $ptype, 'E_EMPTY' ) : undef if $data_read_len == 1;

  confess "unknown or forbidden PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', keys %PROTOCOL_ALLOW ) . "]" unless exists $PROTOCOL_ALLOW{ $ptype };
  my $proto = $PROTOCOL_TYPES{ $ptype };

  my $hr;
  if( $ptype eq 'b' )
    {
    # no unpack for binary messages payload
    $hr = substr( $data, 1 );
    }
  else
    {
    $hr = $proto->{ 'unpack' }->( substr( $data, 1 ) );
    confess "invalid data received from socket stream, expected HASH reference" unless ref( $hr ) eq 'HASH';
    }

  return wantarray ? ( $hr, $ptype, undef ) : $hr;
}

sub socket_protocol_write_message
{
  my $socket  = shift;
  my $ptype   = shift;
  my $hr      = shift; # hash reference or plain data if proto is 'b'inary
  my $timeout = shift;

  confess "unknown or forbidden PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', keys %PROTOCOL_ALLOW ) . "]" unless exists $PROTOCOL_ALLOW{ $ptype };
  my $proto = $PROTOCOL_TYPES{ $ptype };

  my $data;

  if( $ptype eq 'b' )
    {
    # no pack for binary messages payload
    $data = $ptype . $hr;
    }
  else
    {
    confess "expected HASH reference at arg #3" unless ref( $hr ) eq 'HASH';
    $data = $ptype . $proto->{ 'pack' }->( $hr );
    }

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
    # %PROTOCOL_ALLOW is being rebuilt here, so check against the known types
    confess "unknown PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', keys %PROTOCOL_TYPES ) . "]" unless exists $PROTOCOL_TYPES{ $ptype };
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
  return Storable::thaw( shift(), 0 ); # do not allow bless and tie
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

sub protocol_type_hash_url_pack
{
  load_protocol( 'H' );
  return hash2str_url( shift );
}

sub protocol_type_hash_url_unpack
{
  load_protocol( 'H' );
  return str2hash_url( shift );
}

##############################################################################

=pod


=head1 NAME

  Data::Tools::Socket::Protocols provides transparent serialization on top
  of the Data::Tools::Socket message functions.

=head1 SYNOPSIS

  use Data::Tools::Socket::Protocols qw( :all );  # import all functions
  use Data::Tools::Socket::Protocols;             # the same as :all :)
  use Data::Tools::Socket::Protocols qw( :none ); # do not import anything

  # --------------------------------------------------------------------------

  # send a hash reference, serialized with the 'j'son protocol
  socket_protocol_write_message( $socket, 'j', $hash_ref, $timeout );

  # read it back, the protocol type is taken from the message itself
  my $hash_ref = socket_protocol_read_message( $socket, $timeout );

  # in list context the protocol type and an error string are returned too
  my ( $hash_ref, $ptype, $error ) =
      socket_protocol_read_message( $socket, $timeout );

  # the 'b'inary protocol carries plain data instead of a hash reference
  socket_protocol_write_message( $socket, 'b', $raw_data, $timeout );

  # --------------------------------------------------------------------------

  # restrict which protocol types will be accepted and sent
  socket_protocols_allow( 'bjh' );      # only binary, json and hash
  socket_protocols_allow( 'b', 'jh' );  # the same, arguments are concatenated
  socket_protocols_allow( '*' );        # allow all of them again

  # --------------------------------------------------------------------------

=head1 PROTOCOL TYPES

A protocol type is a single character, sent as the first byte of every
message. The rest of the message is the payload, serialized accordingly:

  'b'  binary,        payload is plain data, not a hash reference
  'p'  Storable       (nfreeze/thaw)
  'e'  Sereal
  's'  Data::Stacker
  'j'  JSON
  'x'  XML::Simple
  'h'  hash2str()     from Data::Tools, needs no extra module
  'H'  hash2str_url() from Data::Tools, needs no extra module

Except for 'b', the payload is always a hash reference.

The module needed by a protocol type is loaded on demand, the first time
that type is actually used, so a missing module is only a problem if the
corresponding protocol type is used. 'b', 'h' and 'H' need no extra module.

  NOTE: Storable is a core module and JSON is already required by
        Data::Tools, so those types work out of the box. Sereal,
        Data::Stacker and XML::Simple are not required by this
        distribution and may need to be installed separately.

=head1 FUNCTIONS

=head2 socket_protocol_write_message( $socket, $ptype, $data, $timeout )

Serializes $data according to the $ptype protocol type, prefixes it with the
protocol type character and sends it with socket_write_message().

$data must be a hash reference, unless $ptype is 'b', in which case it is
plain data.

Returns 1 on success or undef if the message could not be sent.

Confesses if $ptype is not a known or currently allowed protocol type, or if
$data is not a hash reference for a non-binary protocol type.

=head2 socket_protocol_read_message( $socket, $timeout, $opt )

Reads a message with socket_read_message(), takes the protocol type from its
first byte and deserializes the rest accordingly.

In scalar context returns the deserialized data, or undef on error.

In list context returns:

  ( $data, $ptype, $error )

$error is undef when everything went fine, otherwise it is one of the error
strings of socket_read_message(), or 'E_EMPTY' if the message carries no
protocol type byte or no payload after it.

Confesses if the incoming protocol type is not known or not currently
allowed, or if a non-binary protocol type does not deserialize into a hash
reference.

=head2 socket_protocols_allow( @protocol_types )

Restricts which protocol types will be accepted and sent. The arguments are
concatenated and then split into single characters, so these are the same:

  socket_protocols_allow( 'bjh' );
  socket_protocols_allow( 'b', 'j', 'h' );

A single '*' allows all known protocol types again.

By default all protocol types are allowed. Confesses if an unknown protocol
type is given, in which case the allowed set is left incomplete, so pass all
wanted types in one call.

=head1 REQUIRED MODULES

Data::Tools::Socket::Protocols uses:

  * Data::Tools
  * Data::Tools::Socket

and, on demand and only for the corresponding protocol types:

  * Storable, Sereal, Data::Stacker, JSON, XML::Simple

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
