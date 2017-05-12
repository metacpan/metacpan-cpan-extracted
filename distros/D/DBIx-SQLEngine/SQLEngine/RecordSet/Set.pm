=head1 NAME

DBIx::SQLEngine::RecordSet::Set - Array of Record Objects

=head1 SYNOPSIS

  use DBIx::SQLEngine::RecordSet::Set;

  $record_set = DBIx::SQLEngine::RecordSet::Set->new( @records );

  $record_set = $record_class->fetch_select( criteria => { status => 2 } );
  
  print "Found " . $record_set->count() . " records";

  $record_set->filter( { 'status' => 'New' } );
  $record_set->sort( 'creation_date' );
  
  foreach ( 0 .. $record_set->count() ) { 
    print $record_set->record( $_ )->name();
  }
  
  foreach ( $record_set->range_records( 11, 20 ) ) { 
    print $_->name();
  }


=head1 DESCRIPTION

This package is not yet complete.

The base implementation of RecordSet is an array of Record references.

=cut

########################################################################

package DBIx::SQLEngine::RecordSet::Set;

use strict;

########################################################################

########################################################################

=head2 Constructor 

=over 4

=item new()

  $class->new ( @records ) : $recordset

Array constructor.

=item clone()

  $recordset->clone() : $recordset

Create a shallow copy of the record set.

=back

=cut

# $rs = DBIx::SQLEngine::RecordSet::Set->new( @records );
sub new {
  my $callee = shift;
  my $package = ref $callee || $callee;
  my $set = bless [], $package;
  $set->init( @_ );
  return $set;
}

sub clone {
  my $self = shift;
  $self->new( @$self );
}

########################################################################

=head2 Contents 

=over 4

=item init()

  $recordset->init ( @records ) 

Array content setter.

=item records()

  $rs->records() : @records

Array content accessor.

=back

=cut

# $rs->init( @records );
sub init {
  my $self = shift;
  
  @$self = ( scalar @_ == 1 and ref($_[0]) eq 'ARRAY' ) ? @{ $_[0] } : @_;
}

# @records = $rs->records();
sub records {
  my $records = shift;
  @$records
}

########################################################################

########################################################################

=head2 Positional Access 

=over 4

=item count()

  $count = $rs->count();

Returns the number of records in this set.

=item record()

  $record = $rs->record( $position );

Return the record in the indicated position in the array. Returns nothing if position is undefined.

Indexes start with zero. Negative indexes are counted back from the end, with -1 being the last, -2 being the one before that, and so forth.

=item last_record

  $record = $rs->last_record();

Return the last record in the array.

=back

=cut

# $count = $rs->count();
sub count {
  my $self = shift;
  scalar @$self;
}

# $record = $rs->record( $position );
sub record {
  my $self = shift;
  my $position = shift;
  return unless ( defined $position and length $position );
  $position += $self->count if ( $position < 0 );
  return unless ( $position !~ /\D/ and $position <= $#$self);
  $self->[ $position ];
}

# @records = $rs->get_records( @positions );
sub get_records {
  my $self = shift;
  map { $self->record( $_ ) } @_
}

########################################################################

# $record = $rs->last_record();
sub last_record {
  my $self = shift;
  return unless $self->count;
  $self->record( $self->count - 1 );
}

########################################################################

########################################################################

=head2 Positional Subsets 

=over 4

=item range_set()

  $clone = $rs->range_set( $start_pos, $stop_pos );

Return a copy of the current set containing only those records at or between the start and stop positions.

=item range_records()

  @records = $rs->range_records( $start_pos, $stop_pos );

Return the records at or between the start and stop positions.

=back

=cut

# $clone = $rs->range_set( $start_pos, $stop_pos );
sub range_set {
  my $self = shift;
  my ( $start, $end ) = @_;
  if ( $start < 0 ) { $start = 0 }
  if ( $end > $#$self ) { $end = $#$self }
   
  $self->new( $self->get_records( $start .. $end ) );
}

# @records = $rs->range_records( $start_pos, $stop_pos );
sub range_records {
  my $self = shift;
  my ( $start, $end ) = @_;
  if ( $start < 0 ) { $start = 0 }
  if ( $end > $#$self ) { $end = $#$self }
   
  $self->get_records( $start .. $end )
}

########################################################################

########################################################################

=head2 Sorting

Use of these methods requires the Data::Sorting module from CPAN. 

See L<Data::Sorting> for more information.

=over 4

=item sort()

  $rs->sort( @fieldnames );

Sort the contents of the set.

=item sorted_set()

  $clone = $rs->sorted_set( @fieldnames );

Return a sorted copy of the current set.

=item sorted_records()

  @records = $rs->sorted_records( @fieldnames );

Return the records from the current set, in sorted order.

=back

=cut

# $rs->sort( @fieldnames );
sub sort {
  my $self = shift;
  local @_ = @{ $_[0] } if ( scalar @_ == 1 and ref $_[0] eq 'ARRAY' );
  require Data::Sorting;
  Data::Sorting::sort_array(@$self, @_);
}

# $clone = $rs->sorted_set( @fieldnames );
sub sorted_set {
  my $self = shift;
  my $clone = $self->clone();
  $clone->sort( @_ );
  return $clone;
}

# @records = $rs->sorted_records( @fieldnames );
sub sorted_records {
  my $self = shift;
  my $clone = $self->clone();
  $clone->sort( @_ );
  $clone->records();
}

########################################################################

sub reverse {
  my $rs = shift;
  @$rs = reverse @$rs;
}

########################################################################

########################################################################

=head2 Criteria Matching

B<Caution:> This set of methods is currently not working.

=over 4

=item filter()

  $rs->filter( $criteria );

Remove non-matching records from the set.

=item filtered_set()

  $clone = $rs->filtered_set( $criteria );

Return a set containing only the matching records from the current set.

=item filtered_records()

  @records = $rs->filtered_records( $criteria );

Return the matching records from the current set.

=back

=cut

use DBIx::SQLEngine::Criteria qw( new_group_from_values );

# $rs->filter( $criteria );
sub filter {
  my $self = shift;
  
  my $criteria = shift
	or return;
  if (ref $criteria eq 'ARRAY') { 
    $criteria = new_group_from_values(@$criteria);
  } elsif (ref $criteria eq 'HASH') {
    $criteria = DBIx::SQLEngine::Criteria->new_from_hashref($criteria);
  } elsif (ref $criteria eq 'CODE') {
    @$self = grep { $criteria->( $_ ) } @$self;
    return;
  } 
  
  @$self = $criteria->matchers($self);
}

# $clone = $rs->filtered_set( $criteria );
sub filtered_set {
  my $self = shift;
  my $clone = $self->clone();
  $clone->filter( @_ );
  return $clone;
}

# @records = $rs->filtered_records( $criteria );
sub filtered_records {
  my $self = shift;
  my $clone = $self->clone();
  $clone->filter( @_ );
  $clone->records();
}

########################################################################

########################################################################

# @results = $rs->visit_sub( $subref, @$leading_args, @$trailing_args );
sub visit_sub {
  my $rs = shift;  
  my $subref = shift;
  my @pre_args = map { ref($_) ? @$_ : defined($_) ? $_ : () } shift;
  my @post_args = map { ref($_) ? @$_ : defined($_) ? $_ : () } shift;
  my @result;
  foreach my $record ( $rs->records ) {
    push @result, $subref->( @pre_args, $record, @post_args )
  }
  return @result;
}

########################################################################

# $numeric = $rs->sum( $fieldname );
sub sum {
  my $rs = shift;  
  my $field = shift;
  my $sum = 0;
  foreach ( $rs->visit_sub( sub { ( shift )->$field() } ) ) {
    $sum += $_;
  }
  return $sum;
}

########################################################################

########################################################################

# $rs->add_records( @records );
sub add_records {
  my $rs = shift;
  my %record_ids = map { $_->id => 1 } $rs->records;
  push @$rs, grep { ! ( $record_ids{ $_->id } ++ ) } @_
}

########################################################################

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
