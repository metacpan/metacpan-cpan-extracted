##############################
#
# Bio::MAGE::Association
#
##############################
package Bio::MAGE::Association;

use strict;
use Carp;

use Exporter;
use base qw/Exporter/;

use vars qw(@EXPORT_OK %EXPORT_TAGS);

use constant {
  CARD_1 => '1',
  CARD_0_OR_1 => '0..1',
  CARD_1_TO_N => '1..N',
  CARD_0_TO_N => '0..N',
};

@EXPORT_OK = ('CARD_1', 'CARD_0_OR_1', 'CARD_0_TO_N', 'CARD_1_TO_N');

 %EXPORT_TAGS = (CARD => [@EXPORT_OK]);

=head1 Bio::MAGE::Association

=head2 SYNOPSIS

  use Bio::MAGE::Association qw(:CARD);

  # creating an empty instance
  my $association = Bio::MAGE::Association->new();

  # populating the instance in the constructor
  my $association = Bio::MAGE::Association->new(self=>$assoc_end1,
                                                       other=>$assoc_end2);

  # setting and retrieving the association ends
  my $self_end = $association->self();
  $association->self($value);

  my $other_end = $association->other();
  $association->other($value);

=head2 DESCRIPTION

This class holds the two association ends for each UML
association. C<self> is the end nearest the class of interest, while
C<other> is the end furthest away. The ends are of type
C<Bio::MAGE::Association::End>.

=head2 CARDINALITY

Associations in UML have a C<cardinality> that determines how many
objects can be associated. In the C<Bio::MAGE::Association>
modulte, C<cardinality> has two primary dimensions: B<optional> or
B<required>, and B<single> or B<list>. So there are four combinations
of the two dimensions:

=over 4

=item * 0..1

This is an B<optional> B<single> association, meaning it can have one
object associated, but it is optional.

=item * 1

This is a B<required> B<single> association, meaning it B<must> have
exactly one object associated.

=item * 0..N

This is an B<optional> B<list> association, meaning it can have many
objects associated.

=item * 1..N

This is an B<required> B<list> association, meaning it must have B<at
least> one object, but it B<may> have many.

=back

There are four constants defined in this module for handling the
cardinalities, and they can be imported into an application using the
B<CARD> import tag:

  use Bio::MAGE::Association qw(:CARD);

The four constants are: B<CARD_0_OR_1>, B<CARD_1>, B<CARD_0_TO_N>, and
B<CARD_1_TO_N>.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  if (scalar @_) {
    my %args = @_;
    foreach my $key (keys %args) {
      no strict 'refs';
      $self->$key($args{$key});
    }
  }
  return $self;
}

sub self {
  my $self = shift;
  if (scalar @_) {
    $self->{__SELF} = shift;
  }
  return $self->{__SELF};
}

sub other {
  my $self = shift;
  if (scalar @_) {
    $self->{__OTHER} = shift;
  }
  return $self->{__OTHER};
}

##############################
#
# Bio::MAGE::Association::End
#
##############################
package Bio::MAGE::Association::End;

use strict;
use Carp;

=head1 Bio::MAGE::Association::End

=head2 SYNOPSIS

  use Bio::MAGE::Association qw(:CARD);

  # creating an empty instance
  my $assoc_end = Bio::MAGE::Association::End->new();

  # populating the instance in the constructor
  my $assoc_end = Bio::MAGE::Association::End->new(
						name=>$name,
						is_ref=>$bool,
						cardinality=>CARD_0_TO_N,
						class_name=>$class_name,
						documentation=>$doc_string,
						rank=>$rank,
						ordered=>$bool,
					       );

  # setting and retrieving object attributes
  my $name = $assoc_end->name();
  $assoc_end->name($value);

  my $is_ref = $assoc_end->is_ref();
  $assoc_end->is_ref($value);

  my $cardinality = $assoc_end->cardinality();
  $assoc_end->cardinality($value);

  my $class_name = $assoc_end->class_name();
  $assoc_end->class_name($value);

  my $documentation = $assoc_end->documentation();
  $assoc_end->documentation($value);

  my $rank = $assoc_end->rank();
  $assoc_end->rank($value);

  my $ordered = $assoc_end->ordered();
  $assoc_end->ordered($value);

  #
  # Utility methods
  #

  # does this end of list cardinality (0..N or 1..N)
  my $bool = $assoc_end->is_list();

=head2 DESCRIPTION

This class stores the information in a single UML association end.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  if (scalar @_) {
    my %args = @_;
    foreach my $key (keys %args) {
      no strict 'refs';
      $self->$key($args{$key});
    }
  }
  return $self;
}

sub cardinality {
  my $self = shift;
  if (scalar @_) {
    $self->{__CARDINALITY} = shift;
  }
  return $self->{__CARDINALITY};
}

sub rank {
  my $self = shift;
  if (scalar @_) {
    $self->{__RANK} = shift;
  }
  return $self->{__RANK};
}

sub ordered {
  my $self = shift;
  if (scalar @_) {
    $self->{__ORDERED} = shift;
  }
  return $self->{__ORDERED};
}

sub is_ref {
  my $self = shift;
  if (scalar @_) {
    $self->{__IS_REF} = shift;
  }
  return $self->{__IS_REF};
}

sub name {
  my $self = shift;
  if (scalar @_) {
    $self->{__NAME} = shift;
  }
  return $self->{__NAME};
}

sub class_name {
  my $self = shift;
  if (scalar @_) {
    $self->{__CLASS_NAME} = shift;
  }
  return $self->{__CLASS_NAME};
}

sub documentation {
  my $self = shift;
  if (scalar @_) {
    $self->{__DOCUMENTATION} = shift;
  }
  return $self->{__DOCUMENTATION};
}

sub is_list {
  my $self = shift;
  return (($self->{__CARDINALITY} eq Bio::MAGE::Association::CARD_0_TO_N)
    or ($self->{__CARDINALITY} eq Bio::MAGE::Association::CARD_1_TO_N))
}

1;
