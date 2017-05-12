package Biblio::RFID::Reader::API;

use warnings;
use strict;

=head1 NAME

Biblio::RFID::Reader::API - low-level RFID reader documentation

=cut

=head1 MANDATORY METHODS

Each reader must implement following hooks as sub-classes.

=head2 init

  $self->init;

=head2 inventory

  my @tags = $self->invetory;

=head2 read_blocks

  my $hash = $self->read_blocks( $tag );

All blocks are under key which is tag UID with array of blocks returned from reader

  $hash = { 'E000000123456789' => [ 'blk1', 'blk2', ... ] };

L<Biblio::RFID::Reader::3M810> sends tag UID with data payload, so we might expect
to receive response from other tags from protocol specification, 

=head2 write_blocks

  $self->write_blocks( $tag => $bytes );

  $self->write_blocks( $tag => [ 'blk1', 'blk2', ... ] );

=head2 read_afi

  my $afi = $self->read_afi( $tag );

=head2 write_afi

  $self->write_afi( $tag => $afi );


=head1 METHODS

=head2 new

Just calls C<init> in reader implementation so this class
can be used as simple stub base class like
L<Biblio::RFID::Reader::librfid> does

=cut

sub new {
	my $class = shift;
	my $self = {@_};
	bless $self, $class;
	$self->init && return $self;
}

1;
