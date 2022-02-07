#/usr/bin/env perl
###############################################################################
#
# @file CSV.pm
#
# @brief Eulerian Data Warehouse REST CSV Parser Module definition.
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
package API::Eulerian::EDW::Parser::CSV;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# Inherited interface from API::Eulerian::EDW::Parser
#
use parent 'API::Eulerian::EDW::Parser';
#
# Import Text::CSV
#
use Text::CSV;
#
# @brief
#
# @param $class - API::Eulerian::EDW::Parser class.
# @param $path - File Path.
# @param $uuid - Request uuid.
#
# @return API::Eulerian::EDW::Json Parser.
#
sub new
{
  my ( $class, $path, $uuid ) = @_;
  my $self;
  my $file;
  my $fd;

  if( open( $file, '<:encoding(utf8)', $path ) ) {
    $self = $class->SUPER::new( $path, $uuid );
    $self->{ _FILE } = $file;
    $self->{ _PARSER } = Text::CSV->new( {
      binary => 1,
      auto_diag => 1,
      sep_char => ',',
    } );
  }

  return $self;
}
#
# @brief
#
# @param $self
#
# @return
#
sub file
{
  return shift->{ _FILE };
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
sub do
{
  my ( $self, $hooks ) = @_;
  my $parser = $self->parser();
  my $file = $self->file();
  my $uuid = $self->uuid();
  my @headers = ();
  my $start = 0;
  my $end = 0;
  my @rows;
  my $line;

  # in case of Noop - do not do any treatment on returned data - exit
  if ( $hooks eq 'API::Eulerian::EDW::Hook::Noop' ) {
    return;
  }

  # Process Headers line
  $line = <$file>; chomp $line;
  if( $parser->parse( $line ) ) {
    foreach my $field ( $parser->fields() ) {
      push @headers, [ 'UNKNOWN', $field ];
    }
    $hooks->on_headers( $uuid, $start, $end, \@headers );
  }

  # Process Next lines
  while( my $line = <$file> ) {
    chomp $line;
    if( $parser->parse( $line ) ) {
      @rows = [ $parser->fields() ];
      $hooks->on_add( $uuid, \@rows );
    }
  }

  $hooks->on_status( $uuid, '', 0, 'Success', 0 );

}
#
# Endup module properly
#
1;
