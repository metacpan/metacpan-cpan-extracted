
=head1 NAME

Bio::Metabolic::Substrate::Cluster - Perl extension for lists of
metabolic compounds

=head1 SYNOPSIS

  use Bio::Metabolic::Substrate::Cluster;

  $cl = Bio::Metabolic::Substrate::Cluster->new(@substrate_list);

  $clcopy = $cl->copy;

  @list = $cl->list;

  if ($cl->has($substrate)) { ... }

  $substrate_nr = $cl->which($substrate);

  $cl->add_substrates(@substrate_list);

  $removed = $cl->remove_substrates(@substrate_list);

=head1 DESCRIPTION

This class implements the object class for clusters of biochemical compounds.
Essentially, a Bio::Metabolic::Substrate::Cluster object is an arrayref to list
of Bio::Metabolic::Substrate objects.

=head2 EXPORT

None

=head2 OVERLOADED OPERATORS

  String Conversion
    $string = "$cluster";
    print "\$cluster = '$cluster'\n";

  Addition
    $clbig = $cl1 + $cl2;

=head2 CLASS METHODS

  $cl = Bio::Metabolic::Substrate::Cluster->new(@substrate_list);

The constructor method creating a Bio::Metabolic::Substrate::Cluster
object from a list of Bio::Metabolic::Substrate objects.


=head2 OBJECT METHODS

  $clcopy = $cl->copy;

creates an exact copy of a cluster

  @list = $cl->list;

returns a list of Bio::Metabolic::Substrate objects


  $cl->has($substrate))

returns 1 if $substrate is a member of $cl, 0 otherwise


  $substrate_nr = $cl->which($substrate);

returns the index of the element representing $substrate

 EXAMPLE: @list = $cl->list;
          if ($cl->has($substrate)) {
            $ind = $cl->which($substrate);
            print "BOO!\n" if ($substrate == $list[$ind]); # prints "BOO!"
          }


  $cl->add_substrates(@substrate_list);

adds the list of Bio::Metabolic::Substrate objects to the cluster $cl


  $removed = $cl->remove_substrates(@substrate_list);

removes the list of Bio::Metabolic::Substrate objects if present.
Returns a cluster containing all removed substrates.



=head1 AUTHOR

Oliver Ebenhöh, oliver.ebenhoeh@rz.hu-berlin.de

=head1 SEE ALSO

Bio::Metabolic, Bio::Metabolic::Substrate.

=cut

package Bio::Metabolic::Substrate::Cluster;

require 5.005_62;
use strict;
use warnings;

require Exporter;

use Carp;

use overload
  "+"    => \&add_clusters,
  "\"\"" => \&cluster_to_string;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::Metabolic::Substrate::Cluster ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '0.06';

=head1 METHODS

=head2 Constructor new

Creates a new instance of a Bio::Metabolic::Substrate::Cluster object.
Can be invoked as class method or object method. In the first case returns
a Bio::Metabolic::Substrate::Cluster genereted from the arguments (array or arrayref).
In the second case it returns a clone.

  $cl = Bio::Metabolic::Substrate::Cluster->new($substrate1, $substrate2, $substrate3 ...);

  $cl = Bio::Metabolic::Substrate::Cluster->new([$substrate1, $substrate2, $substrate3 ...]);

  $cl = $proto->new();

=cut

sub new {
    my $proto = shift;
    my $pkg   = ref($proto) || $proto;

    my @substrates;
    if ( ref($proto) eq 'Bio::Metabolic::Substrate::Cluster' ) {
        @substrates = $proto->list;
    }
    else {
        @substrates = ref( $_[0] ) eq 'ARRAY' ? @{ $_[0] } : @_;
    }

    my $new_cluster = $pkg->_new_empty();

    $new_cluster->add_substrates(@substrates);

    return $new_cluster;
}

# method _new_empty() for internal use only.
# Returns an empty object

sub _new_empty {
    my $pkg = shift;
    $pkg = ref($pkg) if ref($pkg);

    return bless {
        pos        => {},
        substrates => [],
    } => $pkg;
}

# accessor method _position for internal use only

sub _position {
    my $self = shift;
    $self->{pos} = shift if @_;
    return $self->{pos};
}

=head2 Method copy

  copy() is exactly the same as $cl2 = $cl1->new();

=cut

sub copy {
    my $cluster = shift;
    return ref($cluster)->new( $cluster->list );
}

=head2 Method list

list() returns the substrates of the objects as a list in array context, as an arrayref
in scalar context.

=cut

sub list {
    my $cluster = shift;
    return wantarray ? @{ $cluster->{substrates} } : $cluster->{substrates};
}

=head2 Method cluster_to_string

cluster_to_string() returns a readable string listing the substrates in the object.

=cut

sub cluster_to_string {
    my $cluster = shift;

    return "(" . join( ",", $cluster->list ) . ")";
}

=head2 Method has

has($sub) returns 1 if the object contains $sub, 0 otherwise.

=cut

sub has {
    my $cluster   = shift;
    my $substrate = shift;

    return defined $cluster->_position->{ $substrate->name };

    #  my $hassub = 0;
    #    foreach my $sub ( $cluster->list ) {
    #        return 1 if $sub == $substrate;
    #    }

    #    return 0;
}

=head2 method add_substrates

this method modifies the object in-place, adding the substrates passed as arguments
(array or arrayref)

=cut

sub add_substrates {
    my $cluster    = shift;
    my @substrates = ref( $_[0] ) eq 'ARRAY' ? @{ $_[0] } : @_;

    while ( my $substrate = shift(@substrates) ) {

        #        push( @$cluster, $substrate ) unless $cluster->has($substrate);
        next if $cluster->has($substrate);
        my $listref = $cluster->list;
        $cluster->_position->{ $substrate->name } = $#$listref + 1;
        push( @$listref, $substrate );
    }
}

#sub force_add_substrates {
#  my $cluster = shift;
#  my @substrates = @_;

#  while (my $substrate = shift(@substrates)) {
#    push(@$cluster,$substrate);
#  }
#}

=head2 method remove_substrates

this method modifies the object in-place, removing the substrates passed as arguments
from the list (array or arrayref).
Returns the removed substrates as Bio::Metabolic::Substrate::Cluster.

=cut

sub remove_substrates {
    my $cluster    = shift;
    my @substrates = ref( $_[0] ) eq 'ARRAY' ? @{ $_[0] } : @_;

    my @removed = ();
    while ( my $substrate = shift(@substrates) ) {
        next unless $cluster->has($substrate);
        my $rempos  = $cluster->which($substrate);
        my $listref = $cluster->list;
        push( @removed, splice( @$listref, $rempos, 1 ) );
        delete $cluster->_position->{ $substrate->name };
        foreach my $v ( values %{ $cluster->_position } ) {
            $v-- if $v > $rempos;
        }
    }

    #    while ( my $substrate = shift(@substrates) ) {
    #        for ( my $i = 0 ; $i < @$cluster ; $i++ ) {
    #            if ( $cluster->[$i] == $substrate ) {
    #                push( @removed, splice( @$cluster, $i, 1 ) );
    #            }
    #        }
    #    }

    return ref($cluster)->new(@removed);
}

=head2 method add_clusters

this method returns a cluster containing substrates from an arbitrary large list of clusters.

=cut

sub add_clusters {
    my @clusters = @_;

    # this is due to an extra value passed by the overload Module
    pop(@clusters)
      if ( ref( $clusters[ @clusters - 1 ] ) ne ref( $clusters[0] ) );

    croak("add_clusters needs at least one clusters!") if @clusters == 0;

    my $new_cluster = ref( $clusters[0] )->new;

    foreach my $cluster (@clusters) {
        $new_cluster->add_substrates( $cluster->list );
    }

    return $new_cluster;
}

=head2 method which

If $cl is Bio::Metabolic::Substrate::Cluster, which($substrate) returns the index
of the list containing $substrates.
I.e.
  $i = $cl->which($substrate);
  @list = $cl->list;
  print "TRUE\n" if $list[$i] == $substrate; # prints 'TRUE'

=cut

sub which {
    my $self = shift;

    #    my @slist     = shift->list;
    my $substrate = shift;

    return $self->_position->{ $substrate->name };

    #    my $cnt;
    #    for ( $cnt = 0 ; $cnt < @slist ; $cnt++ ) {
    #        last if $slist[$cnt] == $substrate;
    #    }
    #    $cnt = undef if $cnt == @slist;
    #    return $cnt;
}

1;
__END__
