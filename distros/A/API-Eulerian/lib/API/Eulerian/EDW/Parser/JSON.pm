#/usr/bin/env perl
###############################################################################
#
# @file Json.pm
#
# @brief Eulerian Data Warehouse REST Json Parser Module definition.
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 26/11/2021
#
# @version 1.0
#
###############################################################################
#
# Setup module name
#
package API::Eulerian::EDW::Parser::JSON;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# Inherited interface from API::Eulerian::EDW::Parser
#
use parent 'API::Eulerian::EDW::Parser';
#
#
#
use JSON::Streaming::Reader;
#
#
#
use FileHandle;
#
# @brief
#
# @param $class - API::Eulerian::EDW::Parser class.
# @param $path - File Path.
# @param $uuid - Request UUID.
#
# @return API::Eulerian::EDW::Json Parser.
#
sub new
{
  my ( $class, $path, $uuid ) = @_;
  my $self;
  my $fd;

  # Setup base class instance
  $self = $class->SUPER::new( $path, $uuid );

  # Create a new FileHandle
  $self->{ _FD } = $fd = FileHandle->new();

  # Open FileHandle
  $fd->open( "< $path" );

  # Create Json parser
  $self->{ _PARSER } = JSON::Streaming::Reader->for_stream( $fd );

  return $self;
}
#
# @brief
#
# @param $self
#
# @return
#
sub parser
{
  return shift->{ _PARSER };
}
#
# @brief
#
# @param $self - API::Eulerian::EDW::Parser
#
use Data::Dumper;
sub do
{
  my ( $self, $hooks ) = @_;
  my $parser = $self->parser();
  my $depth = -1;
  my @in = ();
  my $uuid;
  my $msg;
  my $key;

  # Parse JSON stream
  $parser->process_tokens(
    # Property begin
    start_property => sub
    {
      $key = shift;
    },
    # Property end
    end_property => sub
    {
    },
    # String
    add_string => sub
    {
      my $parent = $in[ $depth ];
      if( ref( $parent ) eq 'ARRAY' ) {
        $parent->[ scalar( @$parent ) ] = shift;
      } elsif( ref( $parent ) eq 'HASH' ) {
        $parent->{ $key } = shift;
      }
    },
    # Number
    add_number => sub
    {
      my $parent = $in[ $depth ];
      if( ref( $parent ) eq 'ARRAY' ) {
        $parent->[ scalar( @$parent ) ] = shift;
      } elsif( ref( $parent ) eq 'HASH' ) {
        $parent->{ $key } = shift;
      }
    },
    # Null
    add_null => sub
    {
      my $parent = $in[ $depth ];
      if( ref( $parent ) eq 'ARRAY' ) {
        $parent->[ scalar( @$parent ) ] = undef;
      } elsif( ref( $parent ) eq 'HASH' ) {
        $parent->{ $key } = undef;
      }
    },
    # Object begin
    start_object => sub
    {
      $in[ ++$depth ] = {};
    },
    # Object end
    end_object => sub
    {
      my $parent = $in[ $depth - 1 ] if $depth > 0;
      if( ref( $parent ) eq 'ARRAY' ) {
        $parent->[ scalar( @$parent ) ] = $in[ $depth ];
      } elsif( ref( $parent ) eq 'HASH' ) {
        $parent->{ $key } = $in[ $depth ];
      }
      if( $depth == 1 ) {
        $msg = $in[ $depth ];
        #print( Dumper( $msg ) . "\n" ); die "";
        $uuid = $msg->{ uuid };
        print( "UUID : $uuid\n" );
        $hooks->on_headers(
          $uuid, $msg->{ from }, $msg->{ to },
          $msg->{ schema }
          );
      }
      $depth--;
    },
    # Array begin
    start_array => sub
    {
      $in[ ++$depth ] = [];
    },
    # Array end
    end_array => sub
    {
      my $parent = $in[ $depth - 1 ] if $depth > 0;
      if( ref( $parent ) eq 'ARRAY' ) {
        $parent->[ scalar( @$parent ) ] = $in[ $depth ];
      } elsif( ref( $parent ) eq 'HASH' ) {
        $parent->{ $key } = $in[ $depth ];
      }
      if( $depth == 2 && $uuid ) {
        $hooks->on_add( $uuid, [ $in[ $depth ] ] );
      }
      $depth--;
    },
  );
  $hooks->on_status( $uuid, '', 0, 'Success', 0 );

}
#
# Endup module properly
#
1;
