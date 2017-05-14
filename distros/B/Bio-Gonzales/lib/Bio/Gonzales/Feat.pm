package Bio::Gonzales::Feat;
use strict;
use warnings;
use Carp;

use Mouse;
use List::MoreUtils qw/zip/;
use Data::Dumper;
use Storable qw(dclone);
use Scalar::Util qw/refaddr/;

our $QUIET_MODE;

our $VERSION = '0.0546'; # VERSION

extends 'Bio::Gonzales::MiniFeat';

has [qw/seq_id start end strand/] => ( is => 'rw', required => 1 );

has [qw/phase score /] => ( is => 'rw' );


sub scf_id { return shift->seq_id(@_); }

sub length { return $_[0]->end - $_[0]->start + 1 }

sub begin { return shift->start(@_) }

our %STRAND_CHAR_TABLE = (
  '+' => 1,
  '-' => -1,
  '.' => 0,
  -1  => '-',
  1   => '+',
  0   => '.',
);

sub Convert_strand { return $STRAND_CHAR_TABLE{ $_[-1] } }


sub sort_subfeats {
  my ($self) = @_;

  my @sf = sort { ( $a->start <=> $b->start ) || ( $b->end <=> $a->end ) } @{ $self->subfeats };
  $self->subfeats( \@sf );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Bio::Gonzales::Feat - a sequence feature

=head1 SYNOPSIS

    Bio::Gonzales::Feat->new(
        seq_id => 'chr01',
        source => 'glimmerhmm',
        type   => 'exon',
        start  => 324,
        end    => 6342,
        strand => -1,
        attributes => { ID => [ 'exon01' ], Parent => [ 'gene01', 'gene02' ] },
    );

=head1 DESCRIPTION

Represents a sequence feature. The field C<attributes> is not required to
create an object of class Bio::Gonzales::Feat. This class is based on the
L<Sequence Ontology GFF3 specification|http://www.sequenceontology.org/gff3.shtml>

=head1 METHODS

=over 4

=item B<< \%attributes = $f->attr >>

=item B<< \%attributes = $f->attributes >>

=item B<< $sequence_id = $f->seq_id >>

=item B<< $souce = $f->source >>

=item B<< $f->source($new_source) >>

Gets and sets the source attribute of the feature.

=item B<< $type = $f->type >>

=item B<< $f->type($new_type) >>

Gets and sets the type attribute of the feature.

=item B<< $start_coord = $f->start >>

=item B<< $start_coord = $f->begin >>

=item B<< $f->start($start_1_based_coord) >>

=item B<< $f->begin($start_1_baed_coord) >>

Get or set the start coord of the feature.

=item B<< $f->end >>

The same syntax as C<$f->start>, only for the end coordianate.

=item B<< $f->strand($strand) >>

=item B<< $strand = $f->strand >>

Set or get the strand. The strand can be -1 (minus strand), 0 (strand unknown) or 1 (plus strand).

=item B<< $phase = $f->phase >>

=item B<< $f->phase($phase) >>

Gets or sets the phase.

=item B<< $score = $f->score >>

=item B<< $f->score($score) >>

Gets or sets the score.

=item B<< $f->attributes >>

=item B<< $f->attr >>

Get or set the attributes of the feature. Structure:

    {
        ID => [ 'id01' ],
        Parent => [ 'parent1', 'parent2', ... ]
        ...
    }

=item B<< $f->subfeats >>

Gives access to a general container for subfeature objects. Makes grouping
easier, e.g. for BED output format. An example would be an 'mRNA'-object that
has several exons as subfeatures. 

=item B<< $f->parentfeats >>

The same as C<$f->subfeats>, only with parent relation. This function is
completely unrelated to the C<$f->parent_id> function. C<$f->parent_id> only
accesses the attributes, not the parentfeature container.

=item B<< $f->scf_id >>

This is a synonym for C<$f->seq_id>.

=item B<< $first_value = $f->attr_first($attribute_key) >>

=item B<< $first_value = $f->first_attr($attribute_key) >>

The functions C<attr_first> and C<first_attr> retrieve the value of the first
element of the given attribute. An example would be

  my $id = $f->attr_first("ID");

  # in case of multiple parents only the first entry/parent will be returned.
  my $parent = $f->attr_first("Parent");


=item B<< $id = $f->id >>

Retrieve the value of the "ID" attribute. If a feature has multiple ids, a
warning will be printed. Effectively a shortcut for C<$f->attributes->{ID}[0]>.

=item B<< @ids = $f->ids >>

=item B<< \@ids = $f->ids >>

A shortcut for C<$f->attributes->{ID}>. Returns a list of IDs in list context,
a reference to the ID list in scalar context.

=item B<< @parent_ids = $f->parent_ids >>

=item B<< \@parent_ids = $f->parent_ids >>

A shortcut for C<$f->attributes->{Parent}>. Returns a list of parent IDs in list context,
a reference to the parent ID list in scalar context.

=item B<< $parent_id = $f->parent_id >>

A shortcut for C<$f->attributes->{Parent}[0]>. Gives a warning if multiple
parent ids are present.

=item B<< $f->add_attr(%attributes) >>

To add an attribute, call C<add_attr> with either a hash of the form

  %attributes = (
    ID => "mrna_01",
    Parent => "gene_01"
  );

or

  %attributes = (
    ID => "exon_01",
    Parent => [ "gene_01", "gene_02" ],
  );

=item B<< \@deleted_attributes = $f->del_attr(@attribute_names) >>

=item B<< $deleted_attribute = $f->del_attr($attribute_name) >>

Deletes all attributes in C<@attribute_names>.

=item B<< Bio::Gonzales::Feat->Convert_strand($strand) >>

Convert between numeric and character strand respresentation.


=item B<< $cloned_f = $f->clone >>

Clone the feature, deeply (incl. subfeatures and parentfeatures).

=item B<< $length = $f->length >>

The length (end -start +1)

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
