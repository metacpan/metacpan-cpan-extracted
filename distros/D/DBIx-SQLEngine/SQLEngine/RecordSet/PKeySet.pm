=head1 NAME

DBIx::SQLEngine::RecordSet::PKeySet - A RecordSet which holds primary keys

=head1 SYNOPSIS

  use DBIx::SQLEngine::RecordSet;
  
  $rs = DBIx::SQLEngine::RecordSet->class( 'PKeySet' )->new(@records);

=head1 DESCRIPTION

Provides additional methods for a RecordSet to store primary keys instead of references to records.

B<This package is INCOMPLETE!>

=cut

########################################################################

package DBIx::SQLEngine::RecordSet::PKeySet;

use strict;
use Carp;

########################################################################

=head2 Class and IDs

=over 4

=item * 

$rs = DBIx::SQLEngine::RecordSet::Set->new_class_ids( $class, @ids );

=item * 

$rs->init_class_ids( $class, @ids );

=item * 

( $class, @ids ) = $rs->class_ids();

=back

=head2 Conversions

Each of the below returns a RecordSet blessed into a particular subclass. Returns the original object if it is already of that subclass, or returns a cloned and converted copy.

=over 4

=item * 

@data = $rs->raw();

Returns the contents of the RecordSet as stored internally within the object. Results are dependent on which subclass is in use.

=item * 

$rs = $rs->as_RecordArray;

INCOMPLETE

=item * 

$clone = $rs->as_IDArray;

INCOMPLETE

=item * 

$clone = $rs->as_IDString;

INCOMPLETE

=back

# $rs = DBIx::SQLEngine::RecordSet::Set->new_class_ids( $class, @ids );
sub new_ids {
  my $callee = shift;
  my $package = ref $callee || $callee;
  
  my $self = [];
  bless $self, $package;
  $self->init_class_ids( @_ );
  return $self;
}

# $rs->init_ids( $class, @ids );
sub init_ids {
  my $self = shift;
  my $class = shift;
  
  @$self = map { $class->fetch_id( $_ ) } @_;
}

# @records = $rs->class_ids();
sub class_ids {
  my $self = shift;
  my $class = ref( $self->[0] );
  return $class, map { $_->{id} } @$self;
}

###

sub raw {
  my $self = shift;
  if ( scalar @_ ) {
    @$self = @_;
  } else {
    @$self;
  }
}
# 
# sub as_RecordArray {
#   my $self = shift;
# }
# 
# sub as_IDArray {
#   my $self = shift;
#   EBiz::Database::RecordSet::IDArray->new( $self->records );
# }
# 
# sub as_IDString {
#   my $self = shift;
#   EBiz::Database::RecordSet::IDString->new( $self->records );
# }

########################################################################

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
