package CDB_File::BiIndex::Generator;
$REVISION=q$Revision: 1.4 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );
use CDB_File::Generator;
use strict;

=head1 NAME

CDB_File::BiIndex::Generator - build the cdbmake files for a bidirectional index

=head1 SYNOPSIS

	use CDB_File::BiIndex::Generator;
	$gen = new CDB_File::BiIndex::Generator "test";
	$gen->add_relation("USA", "London");
	$gen->add_relation("Malawi", "Lilongwe");
	$gen->finish();

=head1 DESCRIPTION

A CDB_File::BiIndex is designed to keep pairs of values and be able to look
up bi-directional multivalued relations.  This package is designed to
generate one of these indexes statically using CDB.  

At present this package is a complete hack designed simply to output
the two lists in the very specific case which I need.

=head1 EXAMPLE

Please see the example in the CDB_File::BiIndex documentation.  This shows
both how to generate and use an index.

=cut

$CDB_File::BiIndex::Generator::verbose=0;

=head1 METHODS

=head2 new 

	new (CLASS, database_filenamebase)
	new (CLASS, first_database_filename, second_database_filename)

New opens and sets up the databases ready for writing.

=cut

sub new ($$;$) {
    my $class=shift;
    my $ONE_TWO=shift;
    my $TWO_ONE=shift;
    unless ( defined $TWO_ONE) { 
      $TWO_ONE=$ONE_TWO . '.2-1';
      $ONE_TWO=$ONE_TWO . '.1-2' ;
    }
    my $self={};
    $self->{"one_two"} = new CDB_File::Generator $ONE_TWO;
    $self->{"two_one"} = new CDB_File::Generator $TWO_ONE;
    print STDERR "new CDB..Gen $TWO_ONE $ONE_TWO of first list\n"
      if $CDB_File::BiIndex::Generator::verbose & 16;
    return bless $self, $class;
}

=head1 $gen->add_relation( first , second )

Adds a key value pair to the database.

=cut

sub add_relation ($$$) {
  my ($self, $first, $second)=@_;
  $self->{"one_two"}->add($first, $second);
  $self->{"two_one"}->add($second, $first);
}


=head1 $gen->finish()

Writes the database so that it is ready for use by CDB_BiIndex.

=cut

sub finish ($) {
  my ($self)=@_;
  $self->{"one_two"}->finish();
  $self->{"two_one"}->finish();
}


=head1 add_list_first / add_list_second ->(key, list_reference)

These functions add an entire set of relations of one string to a list
of other strings

C<add_list_first> puts makes the key a key in the first index.
C<add_list_second> puts the list in the first index and the key in the
second.

=cut


sub add_list_first ($$$) {
  my $self=shift;
  my $first=shift;
  print STDERR "adding to $first of first list\n"
    if $CDB_File::BiIndex::Generator::verbose & 8;
  my $seconds=shift;
  _add_list( $self->{"one_two"}, $self->{"two_one"}, $first, $seconds);
}

sub add_list_second ($$$) {
  my $self=shift;
  my $second=shift;
  print STDERR "adding list to $second of second list\n"
    if $CDB_File::BiIndex::Generator::verbose & 8;
  my $firsts=shift;
  _add_list( $self->{"two_one"}, $self->{"one_two"}, $second, $firsts);
}

# internal function which implements the previous two user visible ones.

sub _add_list ($$$$) {
  my $one_two = shift; 
  my $two_one = shift; 
  my $first = shift;
  my $seconds = shift;
  my $second;
  print STDERR "add $first all of $seconds\n"
    if $CDB_File::BiIndex::Generator::verbose & 4;
  foreach $second ( @$seconds ) {
    print STDERR "adding item $first->$second\n"
      if $CDB_File::BiIndex::Generator::verbose & 2;
    $one_two->add($first, $second);
    $two_one->add($second, $first);
  }
}
	       
1; 
# If require was a child, by now it would be so spoiled with people
#keeping it happy that it would be unbearable.  Don't get me wrong, I'm
#not some kind of candidate for 'Victoran Parents' but there are
#limits..
