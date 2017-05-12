=head1 NAME

DBIx::SQLEngine::RecordSet::NextPrev - A RecordSet with a current index

=head1 SYNOPSIS

  use DBIx::SQLEngine::RecordSet;
  
  $rs = DBIx::SQLEngine::RecordSet->class( 'NextPrev' )->new(@records);
  
  while ( $rs->current_record ) {
    print $rs->get_values( 'name' );
    $rs->move_next();
  }
  
  $rs->move_first;
  
  while ( $rs->current_record ) {
    $rs->set_values( 'updated' => time() );
    $rs->save_record();
    $rs->move_next();
  }

=head1 DESCRIPTION

Provides additional methods for a RecordSet to add a current index with previous and next methods.

B<This package is INCOMPLETE!>

=cut

########################################################################

package DBIx::SQLEngine::RecordSet::NextPrev;

use strict;
use Carp;

########################################################################

use Class::MakeMethods ( 
  'Standard::Inheritable:scalar' => 'index_current',
);

sub reset {
  (shift)->index_current( undef )
}

########################################################################

sub index {
  my $self = shift;
  my $offset = ( scalar @_ ) ? shift : 0;
  my $index = $self->index_current + $offset
  ( $index < 0 ) ? undef : $index
}

sub look {
  my $self = shift;
  $self->record( $self->index( @_ ) )
}

sub move {
  my $self = shift;
  $self->index_current( $self->index( @_ ) )
}

########################################################################

sub current_record {
  my $self = shift;
  $self->record( $self->index_current || 0 )
}

sub get_current {
  ( $_[0] )->current_record 
      or croak("No current record at position '" . $self->index_current . "'" )
}

########################################################################

sub index_next {
  (shift)->index( ( scalar @_ ) ? shift : 1 )
}

sub next_record {
  my $self = shift;
  $self->record( $self->index_next( @_ ) )
}

sub move_next {
  my $self = shift;
  $self->index_current( $self->index_next( @_ ) );
  $self->get_current;
}

sub get_next {
  ( $_[0] )->move_next 
      or croak("No next record at position '" . $self->index_current . "'" )
}

########################################################################

sub index_prev {
  (shift)->index( 0 - ( ( scalar @_ ) ? shift : 1 ) )
}

sub prev_record {
  my $self = shift;
  $self->record( $self->index_prev( @_ ) )
}

sub move_prev {
  my $self = shift;
  $self->index_current( $self->index_prev( @_ ) );
  $self->get_current;
}

sub get_prev {
  ( $_[0] )->move_prev 
      or croak("No prev record at position '" . $self->index_current . "'" )
}

########################################################################

sub index_first {
  (shift)->record( 0 ) ? 0 : undef
}

sub look_first {
  my $self = shift;
  $self->record( ( scalar @_ ) ? shift : 0 )
}

sub move_first {
  my $self = shift;
  $self->index_current( 0 );
  $self->get_current;
}

sub get_first {
  (shift)->move_first( @_ ) 
      or croak("No first record, record set is empty" )
}

########################################################################

sub index_last {
  my $self = shift;
  my $count = $self->count;
  $count ? $count - 1 : undef
}

sub look_last {
  my $self = shift;
  $self->record( 0 - ( ( scalar @_ ) ? shift : 1 ) )
}

sub move_last {
  my $self = shift;
  $self->index_current( $self->index_last );
  $self->get_current;
}

sub get_last {
  (shift)->move_last( @_ ) 
      or croak("No last record, record set is empty" )
}

########################################################################

sub before_first {
  ! defined (shift)->index_current 
}

sub at_first {
  (shift)->index_current < 1
}

sub at_either_end {
  my $self = shift;
  $self->at_first or $self->at_last
}

sub at_index {
  my $self = shift;
  $self->index_current == $self->index( @_ )
}

sub at_last {
  my $self = shift;
  ( ! $self->get_current ) and ( $self->index_current >= $self->index_last )
}

sub after_last {
  my $self = shift;
  ( ! $self->get_current ) and ( $self->index_current > $self->index_last )
}

########################################################################

use Class::MakeMethods (
  'Standard::Universal:delegate' => [ 
    [ qw( get_values change_values save_record ) ] => { target=>'get_current' },
  ],
);

########################################################################

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
