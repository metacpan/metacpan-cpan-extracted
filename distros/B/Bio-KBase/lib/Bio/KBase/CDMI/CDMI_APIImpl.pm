package Bio::KBase::CDMI::CDMI_APIImpl;
use strict;
use Bio::KBase::Exceptions;

=head1 NAME

CDMI_API

=head1 DESCRIPTION

The CDMI_API defines the component of the Kbase API that supports interaction with
instances of the CDM (Central Data Model).  A basic familiarity with these routines
will allow the user to extract data from the CS (Central Store).  We anticipate
supporting numerous sparse CDMIs in the PS (Persistent Store).

=head2 Basic Themes

There are several broad categories of routines supported in the CDMI-API.

The simplest is set of "get entity" routines -- each returning data
extracted from instances of a single entity type.  These routines all take
as input a list of ids referencing instances of a single type of entity.
They construct as output a mapping which takes as input an id and
associates as output a set of fields from that instance of the entity.  Each
routine allows the user to specify which fields are desired.

For example, assume you have an input file "Staphylococci," which is a list of genome IDs for each species of Staphylococcus in the database. The get_entity_Genome command is used to retrieve detailed information about each genome in the file. By using different modifiers, you can specify what kind of information you want to display. In this example, the modifier "contigs" was used. Thus, the number next to the genome ID in the output file indicates the number of contigs each Staphylococcus genome has. For a list of available modifiers relating to each identity, please refer to the ER model.

        > / cat Staphylococci | cut -f 1 | get_entity_Genome - f contigs
        kb|g.134        2
        kb|g.636        1
        kb|g.2506        15
        kb|g.9303        1
        kb|g.3801        87
        kb|g.2025        46
        kb|g.2516        13
        kb|g.2603        33
        kb|g.19928        2
        kb|g.1852        131
        kb|g.8476        1
        kb|g.2742        46

To use these routines effectively, a user will need to gradually
become familiar with the entities supported in the CDM.  We suggest
perusing the entity-relationship model that underlies the CDM to
get a good introduction.

The next simplest set of routines provide the "get relationship" routines.  These
take as input a list of ids for a specific entity type, and the give access
to the relationship nodes associated with each entity.  Thus, get_relationship_WasSubmittedBy takes the input genome ID and outputs the ID with an added column showing the source of that particular genome. It is essential to be able to navigate the ER model to successfully implement these commands, since not all relationship types are applicable to each entity.

        > / echo 'kb|g.0' | get_relationship_WasSubmittedBy -to id
        kb|g.0        SEED

Of the remaining CDMI-API routines, most are used to extract data by
"crossing one or more relationships".  Thus,

        my $references = $kbO->fids_to_literature($fids)

takes as input a list of feature ids referenced by the variable $fids.  It
creates a hash ($references) which maps each input key to a list of literature
references.  The construction of the literature references for a given ID involves
crossing relationships from the entity 'Feature' to 'ProteinSequence' to 'Publication'.
We have attempted to package this specific search in a convenient form.  We anticipate
that the number of queries of this last class will grow (especially as new entities are
added to the model).

=head2 Batching queries

A majority of the CS-API routines take a list of ids as input.  Each id may be thought
of as input to a query that produces an output result.  We support processing an input list,
since the performance (which is usually governed by network interactions) is much better
if you process a batch of items, rather than invoking the API repeatedly for each of the
ids.  Normally, the output would be a mapping (a hash for Perl versions) from the
input ids to the output results.  Thus, a routine like

             fids_to_literature

will take a list of feature ids as input.  The returned value will be a mapping from
feature ids (fids) to publication references.

It is a little inconvenient to batch your requests by supplying a list of fids,
but the performance will be much better in most cases.  Please note that you are
controlling the granularity of each request, and in most cases the size of the input
list is not critical.  However, you should note that while batching up hundreds or thousands
of input ids at a time should work just fine, millions may well cause things to break (e.g.,
you may exhaust local memory in your machine as the output results are returned).  As
machines get larger, the appropriate size of the input lists may become largely irrelevant.
For now, we recommend that you experiment a bit and use common sense.

=cut

#BEGIN_HEADER

use strict;
use Bio::KBase::CDMI::CDMI;
use Data::Dumper;
use Carp;
use Bio::KBase::CDMI::CDMI_EntityAPIImpl;
use Sphinx::Search;

our $AUTOLOAD;
sub AUTOLOAD
{
    my($self, @args) = @_;
    my $func = $AUTOLOAD;

    $func =~ s/.+:://;
    if ($func !~ /^(get_entity|get_relationship|all_entities)/)
    {
	die "Unknown function $func";
    }
    return $self->{get_entity}->$func(@args);
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my($cdmi) = @args;
    if (! $cdmi) {
        $cdmi = Bio::KBase::CDMI::CDMI->new();
    }
    $self->{db} = $cdmi;

    my $e = Bio::KBase::CDMI::CDMI_EntityAPIImpl->new($cdmi);
    $self->{get_entity} = $e;

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 fids_to_annotations

  $return = $obj->fids_to_annotations($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is an annotations
fids is a reference to a list where each element is a fid
fid is a string
annotations is a reference to a list where each element is an annotation
annotation is a reference to a list containing 3 items:
	0: a comment
	1: an annotator
	2: an annotation_time
comment is a string
annotator is a string
annotation_time is an int

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is an annotations
fids is a reference to a list where each element is a fid
fid is a string
annotations is a reference to a list where each element is an annotation
annotation is a reference to a list containing 3 items:
	0: a comment
	1: an annotator
	2: an annotation_time
comment is a string
annotator is a string
annotation_time is an int


=end text



=item Description

This routine takes as input a list of fids.  It retrieves the existing
annotations for each fid, including the text of the annotation, who
made the annotation and when (as seconds from the epoch).

=back

=cut

sub fids_to_annotations
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_annotations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_annotations');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_annotations
                    my $kb = $self->{db};
    $return = {};

    for my $id (@$fids) {
        my @resultRows = $kb->GetAll("IsAnnotatedBy Annotation",
                                      "IsAnnotatedBy(from_link) = ?", [$id],
                                      [qw(Annotation(comment)
                                          Annotation(annotator)
                                          Annotation(annotation_time))]);
	if (@resultRows != 0) {
		$return->{$id} = \@resultRows;
	}
    }
    #END fids_to_annotations
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_annotations:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_annotations');
    }
    return($return);
}




=head2 fids_to_functions

  $return = $obj->fids_to_functions($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a function
fids is a reference to a list where each element is a fid
fid is a string
function is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a function
fids is a reference to a list where each element is a fid
fid is a string
function is a string


=end text



=item Description

This routine takes as input a list of fids and returns a mapping
from the fids to their assigned functions.

=back

=cut

sub fids_to_functions
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_functions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_functions');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_functions
    my $kb = $self->{db};
    $return = {};

    for my $id (@$fids) {
        my ($function) = $kb->GetFlat("Feature", 'Feature(id) = ?',
                [$id], 'function');
        $return->{$id} = $function;
    }
    #END fids_to_functions
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_functions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_functions');
    }
    return($return);
}




=head2 fids_to_literature

  $return = $obj->fids_to_literature($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a pubrefs
fids is a reference to a list where each element is a fid
fid is a string
pubrefs is a reference to a list where each element is a pubref
pubref is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a pubrefs
fids is a reference to a list where each element is a fid
fid is a string
pubrefs is a reference to a list where each element is a pubref
pubref is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: a string


=end text



=item Description

We try to associate features and publications, when the publications constitute
supporting evidence of the function.  We connect a paper to a feature when
we believe that an "expert" has asserted that the function of the feature
is basically what we have associated with the feature.  Thus, we might
attach a paper reporting the crystal structure of a protein, even though
the paper is clearly not the paper responsible for the original characterization.
Our position in this matter is somewhat controversial, but we are seeking to
characterize some assertions as relatively solid, and this strategy seems to
support that goal.  Please note that we certainly wish we could also
capture original publications, and when experts can provide those
connections, we hope that they will help record the associations.

=back

=cut

sub fids_to_literature
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_literature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_literature');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_literature
    my $kb = $self->{db};
    $return = {};
    for my $id (@$fids) {
        my @resultRows = $kb->GetAll("Produces IsATopicOf Publication",
                                      "Produces(from_link) = ?", [$id],
                                      [qw(Publication(id)
                                          Publication(link)
                                          Publication(title))]);
        if (@resultRows != 0) {
		$return->{$id} = \@resultRows;
	}

    }
    #END fids_to_literature
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_literature:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_literature');
    }
    return($return);
}




=head2 fids_to_protein_families

  $return = $obj->fids_to_protein_families($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a protein_families
fids is a reference to a list where each element is a fid
fid is a string
protein_families is a reference to a list where each element is a protein_family
protein_family is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a protein_families
fids is a reference to a list where each element is a fid
fid is a string
protein_families is a reference to a list where each element is a protein_family
protein_family is a string


=end text



=item Description

Kbase supports the creation and maintence of protein families.  Each family is intended to contain a set
of isofunctional homologs.  Currently, the families are collections of translations
of features, rather than of just protein sequences (represented by md5s, for example).
fids_to_protein_families supports access to the features that have been grouped into a family.
Ideally, each feature in a family would have the same assigned function.  This is not
always true, but probably should be.

=back

=cut

sub fids_to_protein_families
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_protein_families');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_protein_families
    my $kb = $self->{db};
    $return = {};
    for my $id (@$fids) {
        my @resultRows = $kb->GetFlat("IsMemberOf",
                                      "IsMemberOf(from_link) = ?", [$id],
				     'IsMemberOf(to_link)');
	if (@resultRows != 0) {
                $return->{$id} = \@resultRows;
        }
    }

    #END fids_to_protein_families
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_protein_families');
    }
    return($return);
}




=head2 fids_to_roles

  $return = $obj->fids_to_roles($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a roles
fids is a reference to a list where each element is a fid
fid is a string
roles is a reference to a list where each element is a role
role is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a roles
fids is a reference to a list where each element is a fid
fid is a string
roles is a reference to a list where each element is a role
role is a string


=end text



=item Description

Given a feature, one can get the set of roles it implements using fid_to_roles.
Remember, a protein can be multifunctional -- implementing several roles.
This can occur due to fusions or to broad specificity of substrate.

=back

=cut

sub fids_to_roles
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_roles');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_roles
    my $kb = $self->{db};
    $return = {};
    for my $id (@$fids) {
        my @resultRows = $kb->GetFlat("HasFunctional",
                                      "HasFunctional(from_link) = ?", [$id],
				     'HasFunctional(to_link)');
	if (@resultRows != 0) {
	    my %roles = map { $_ => 1 } @resultRows;
	    my @resultRows = sort keys(%roles);
                $return->{$id} = \@resultRows;
        }
    }

    #END fids_to_roles
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_roles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_roles');
    }
    return($return);
}




=head2 fids_to_subsystems

  $return = $obj->fids_to_subsystems($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a subsystems
fids is a reference to a list where each element is a fid
fid is a string
subsystems is a reference to a list where each element is a subsystem
subsystem is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a subsystems
fids is a reference to a list where each element is a fid
fid is a string
subsystems is a reference to a list where each element is a subsystem
subsystem is a string


=end text



=item Description

fids in subsystems normally have somewhat more reliable assigned functions than
those not in subsystems.  Hence, it is common to ask "Is this protein-encoding gene
included in any subsystems?"   fids_to_subsystems can be used to see which subsystems
contain a fid (or, you can submit as input a set of fids and get the subsystems for each).

=back

=cut

sub fids_to_subsystems
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_subsystems');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_subsystems
    my $kb = $self->{db};
    $return = {};
    for my $id (@$fids) {
        my @resultRows = $kb->GetFlat("IsContainedIn HasRole IsIncludedIn",
                                      "IsContainedIn(from_link) = ?", [$id],
				     'IsIncludedIn(to_link)');
	if (@resultRows != 0) {
	    my %tmp = map { $_ => 1 } @resultRows;
	    @resultRows = sort keys(%tmp);
	    $return->{$id} = \@resultRows;
        }
    }
    #END fids_to_subsystems
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_subsystems');
    }
    return($return);
}




=head2 fids_to_co_occurring_fids

  $return = $obj->fids_to_co_occurring_fids($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a scored_fids
fids is a reference to a list where each element is a fid
fid is a string
scored_fids is a reference to a list where each element is a scored_fid
scored_fid is a reference to a list containing 2 items:
	0: a fid
	1: a float

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a scored_fids
fids is a reference to a list where each element is a fid
fid is a string
scored_fids is a reference to a list where each element is a scored_fid
scored_fid is a reference to a list containing 2 items:
	0: a fid
	1: a float


=end text



=item Description

One of the most powerful clues to function relates to conserved clusters of genes on
the chromosome (in prokaryotic genomes).  We have attempted to record pairs of genes
that tend to occur close to one another on the chromosome.  To meaningfully do this,
we need to construct similarity-based mappings between genes in distinct genomes.
We have constructed such mappings for many (but not all) genomes maintained in the
Kbase CS.  The prokaryotic geneomes in the CS are grouped into OTUs by ribosomal
RNA (genomes within a single OTU have SSU rRNA that is greater than 97% identical).
If two genes occur close to one another (i.e., corresponding genes occur close
to one another), then we assign a score, which is the number of distinct OTUs
in which such clustering is detected.  This allows one to normalize for situations
in which hundreds of corresponding genes are detected, but they all come from
very closely related genomes.

The significance of the score relates to the number of genomes in the database.
We recommend that you take the time to look at a set of scored pairs and determine
approximately what percentage appear to be actually related for a few cutoff values.

=back

=cut

sub fids_to_co_occurring_fids
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_co_occurring_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_co_occurring_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_co_occurring_fids
    my $kb = $self->{db};
    $return = {};
    for my $id (@$fids) {
        my @resultRows = $kb->GetAll("IsInPair Pairing Determines PairSet",
                                      "IsInPair(from_link) = ?", [$id],
				     [qw(IsInPair(to_link) PairSet(score))]);


	if (@resultRows != 0) {
		my @scoredFids;
		for my $resultRow (@resultRows) {
		    my ($pair, $score) = @$resultRow;
		    my ($fid) = grep { $_ ne $id } split /:/, $pair;
		    push @scoredFids, [$fid, $score];
		}
		$return->{$id} = \@scoredFids;
        }
    }

    #END fids_to_co_occurring_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_co_occurring_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_co_occurring_fids');
    }
    return($return);
}




=head2 fids_to_locations

  $return = $obj->fids_to_locations($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a location
fids is a reference to a list where each element is a fid
fid is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a location
fids is a reference to a list where each element is a fid
fid is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int


=end text



=item Description

A "location" is a sequence of "regions".  A region is a contiguous set of bases
in a contig.  We work with locations in both the string form and as structures.
fids_to_locations takes as input a list of fids.  For each fid, a structured location
is returned.  The location is a list of regions; a region is given as a pointer to
a list containing

             the contig,
             the beginning base in the contig (from 1).
             the strand (+ or -), and
             the length

Note that specifying a region using these 4 values allows you to represent a single
base-pair region on either strand unambiguously (which giving begin/end pairs does
not achieve).

=back

=cut

sub fids_to_locations
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_locations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_locations');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_locations
    my $kb = $self->{db};
    $return = {};
    for my $fid (@$fids) {
        my @locs = map { [$_->Contig, $_->Begin, $_->Dir, $_->Length] } $kb->GetLocations($fid);
        $return->{$fid} = \@locs;
    }
    #END fids_to_locations
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_locations:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_locations');
    }
    return($return);
}




=head2 locations_to_fids

  $return = $obj->locations_to_fids($region_of_dna_strings)

=over 4

=item Parameter and return types

=begin html

<pre>
$region_of_dna_strings is a region_of_dna_strings
$return is a reference to a hash where the key is a region_of_dna_string and the value is a fids
region_of_dna_strings is a reference to a list where each element is a region_of_dna_string
region_of_dna_string is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$region_of_dna_strings is a region_of_dna_strings
$return is a reference to a hash where the key is a region_of_dna_string and the value is a fids
region_of_dna_strings is a reference to a list where each element is a region_of_dna_string
region_of_dna_string is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description

It is frequently the case that one wishes to look up the genes that
occur in a given region of a contig.  Location_to_fids can be used to extract
such sets of genes for each region in the input set of regions.  We define a gene
as "occuring" in a region if the location of the gene overlaps the designated region.

=back

=cut

sub locations_to_fids
{
    my $self = shift;
    my($region_of_dna_strings) = @_;

    my @_bad_arguments;
    (ref($region_of_dna_strings) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"region_of_dna_strings\" (value was \"$region_of_dna_strings\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to locations_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'locations_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN locations_to_fids
    my $kb = $self->{db};
    $return = {};
    for my $region (@$region_of_dna_strings) {
        my @fids = $kb->GenesInRegion($region);
        $return->{$region} = \@fids;
    }
    #END locations_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to locations_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'locations_to_fids');
    }
    return($return);
}




=head2 alleles_to_bp_locs

  $return = $obj->alleles_to_bp_locs($alleles)

=over 4

=item Parameter and return types

=begin html

<pre>
$alleles is an alleles
$return is a reference to a hash where the key is an allele and the value is a bp_loc
alleles is a reference to a list where each element is an allele
allele is a string
bp_loc is a reference to a list containing 2 items:
	0: a contig
	1: an int
contig is a string

</pre>

=end html

=begin text

$alleles is an alleles
$return is a reference to a hash where the key is an allele and the value is a bp_loc
alleles is a reference to a list where each element is an allele
allele is a string
bp_loc is a reference to a list containing 2 items:
	0: a contig
	1: an int
contig is a string


=end text



=item Description



=back

=cut

sub alleles_to_bp_locs
{
    my $self = shift;
    my($alleles) = @_;

    my @_bad_arguments;
    (ref($alleles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"alleles\" (value was \"$alleles\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to alleles_to_bp_locs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'alleles_to_bp_locs');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN alleles_to_bp_locs
    my $kb = $self->{db};
    $return = {};
    my $n = @$alleles;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $allele_constraint = "Summarizes(from_link) IN $targets";

    my @res = $kb->GetAll('Summarizes',
			  $allele_constraint,
			  $alleles,
			  'Summarizes(from_link) Summarizes(to_link) Summarizes(position)');

    foreach my $tuple (@res)
    {
	my($allele,$contig,$position) = @$tuple;
	$return->{$allele} = [$contig,$position];
    }

    #END alleles_to_bp_locs
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to alleles_to_bp_locs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'alleles_to_bp_locs');
    }
    return($return);
}




=head2 region_to_fids

  $return = $obj->region_to_fids($region_of_dna)

=over 4

=item Parameter and return types

=begin html

<pre>
$region_of_dna is a region_of_dna
$return is a fids
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$region_of_dna is a region_of_dna
$return is a fids
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description



=back

=cut

sub region_to_fids
{
    my $self = shift;
    my($region_of_dna) = @_;

    my @_bad_arguments;
    (ref($region_of_dna) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"region_of_dna\" (value was \"$region_of_dna\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to region_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'region_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN region_to_fids
    my $kb = $self->{db};
    my($contig,$beg,$strand,$ln) = @$region_of_dna;
    my $region = "$contig" . "_" . $beg . $strand . $ln;
    my @fids = $kb->GenesInRegion($region);
    $return = \@fids;
    #END region_to_fids
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to region_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'region_to_fids');
    }
    return($return);
}




=head2 region_to_alleles

  $return = $obj->region_to_alleles($region_of_dna)

=over 4

=item Parameter and return types

=begin html

<pre>
$region_of_dna is a region_of_dna
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: an allele
	1: an int
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
allele is a string

</pre>

=end html

=begin text

$region_of_dna is a region_of_dna
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: an allele
	1: an int
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
allele is a string


=end text



=item Description



=back

=cut

sub region_to_alleles
{
    my $self = shift;
    my($region_of_dna) = @_;

    my @_bad_arguments;
    (ref($region_of_dna) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"region_of_dna\" (value was \"$region_of_dna\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to region_to_alleles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'region_to_alleles');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN region_to_alleles
    my $kb = $self->{db};
    my($contig,$beg,$strand,$len) = @$region_of_dna;
    my $end;
    if ($strand eq "+")
    {
	$end = $beg + $len - 1;
    }
    else
    {
	($beg,$end) = ($beg - ($len - 1),$beg);
    }
    my @res = $kb->GetAll('IsSummarizedBy',
			  "IsSummarizedBy(from_link) = ? AND IsSummarizedBy(position) >= ? AND IsSummarizedBy(position) <= ?", [$contig,$beg,$end],
			  ["IsSummarizedBy(to_link)","IsSummarizedBy(position)"]);
    $return = \@res;
    #END region_to_alleles
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to region_to_alleles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'region_to_alleles');
    }
    return($return);
}




=head2 alleles_to_traits

  $return = $obj->alleles_to_traits($alleles)

=over 4

=item Parameter and return types

=begin html

<pre>
$alleles is an alleles
$return is a reference to a hash where the key is an allele and the value is a traits
alleles is a reference to a list where each element is an allele
allele is a string
traits is a reference to a list where each element is a trait
trait is a string

</pre>

=end html

=begin text

$alleles is an alleles
$return is a reference to a hash where the key is an allele and the value is a traits
alleles is a reference to a list where each element is an allele
allele is a string
traits is a reference to a list where each element is a trait
trait is a string


=end text



=item Description



=back

=cut

sub alleles_to_traits
{
    my $self = shift;
    my($alleles) = @_;

    my @_bad_arguments;
    (ref($alleles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"alleles\" (value was \"$alleles\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to alleles_to_traits:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'alleles_to_traits');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN alleles_to_traits
    if (@$alleles < 1)  { return $return }

    my $kb = $self->{db};

    my $n = @$alleles;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $allele_constraint = "Summarizes(from_link) IN $targets";

    my @res = $kb->GetAll('Summarizes Contig IsImpactedBy',
			  $allele_constraint,
			  $alleles,
			  'Summarizes(from_link) IsImpactedBy(to_link)');

    foreach my $tuple (@res)
    {
	my($allele,$trait) = @$tuple;
	push(@{$return->{$allele}},$trait);
    }
    #END alleles_to_traits
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to alleles_to_traits:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'alleles_to_traits');
    }
    return($return);
}




=head2 traits_to_alleles

  $return = $obj->traits_to_alleles($traits)

=over 4

=item Parameter and return types

=begin html

<pre>
$traits is a traits
$return is a reference to a hash where the key is a trait and the value is an alleles
traits is a reference to a list where each element is a trait
trait is a string
alleles is a reference to a list where each element is an allele
allele is a string

</pre>

=end html

=begin text

$traits is a traits
$return is a reference to a hash where the key is a trait and the value is an alleles
traits is a reference to a list where each element is a trait
trait is a string
alleles is a reference to a list where each element is an allele
allele is a string


=end text



=item Description



=back

=cut

sub traits_to_alleles
{
    my $self = shift;
    my($traits) = @_;

    my @_bad_arguments;
    (ref($traits) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"traits\" (value was \"$traits\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to traits_to_alleles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'traits_to_alleles');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN traits_to_alleles
    if (@$traits < 1)  { return $return }

    my $kb = $self->{db};

    my $n = @$traits;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $trait_constraint = "Impacts(from_link) IN $targets";
    my @res = $kb->GetAll('Impacts Contig IsSummarizedBy',
			  "$trait_constraint AND Impacts(position) = IsSummarizedBy(position)",
			  $traits,
			  'Impacts(from_link) IsSummarizedBy(to_link)');

    foreach my $tuple (@res)
    {
	my($trait,$allele) = @$tuple;
	push(@{$return->{$trait}},$allele);
    }
    #END traits_to_alleles
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to traits_to_alleles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'traits_to_alleles');
    }
    return($return);
}




=head2 ous_with_trait

  $return = $obj->ous_with_trait($genome, $trait, $measurement_type, $min_value, $max_value)

=over 4

=item Parameter and return types

=begin html

<pre>
$genome is a genome
$trait is a trait
$measurement_type is a measurement_type
$min_value is a float
$max_value is a float
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: an ou
	1: a measurement_value
genome is a string
trait is a string
measurement_type is a string
ou is a string
measurement_value is a float

</pre>

=end html

=begin text

$genome is a genome
$trait is a trait
$measurement_type is a measurement_type
$min_value is a float
$max_value is a float
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: an ou
	1: a measurement_value
genome is a string
trait is a string
measurement_type is a string
ou is a string
measurement_value is a float


=end text



=item Description



=back

=cut

sub ous_with_trait
{
    my $self = shift;
    my($genome, $trait, $measurement_type, $min_value, $max_value) = @_;

    my @_bad_arguments;
    (!ref($genome)) or push(@_bad_arguments, "Invalid type for argument \"genome\" (value was \"$genome\")");
    (!ref($trait)) or push(@_bad_arguments, "Invalid type for argument \"trait\" (value was \"$trait\")");
    (!ref($measurement_type)) or push(@_bad_arguments, "Invalid type for argument \"measurement_type\" (value was \"$measurement_type\")");
    (!ref($min_value)) or push(@_bad_arguments, "Invalid type for argument \"min_value\" (value was \"$min_value\")");
    (!ref($max_value)) or push(@_bad_arguments, "Invalid type for argument \"max_value\" (value was \"$max_value\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to ous_with_trait:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'ous_with_trait');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN ous_with_trait
    my $kb = $self->{db};
    my @res = $kb->GetAll('Measures ObservationalUnit UsesReference',
			  'Measures(from_link) = ? AND Measures(measure_id) = ? AND Measures(value) <= ? AND Measures(value) >= ? AND UsesReference(to_link) = ?',
			  [$trait,$measurement_type,$max_value,$min_value,$genome],
			  'Measures(to_link) Measures(value)');
    $return = \@res;
    #END ous_with_trait
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to ous_with_trait:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'ous_with_trait');
    }
    return($return);
}




=head2 locations_to_dna_sequences

  $dna_seqs = $obj->locations_to_dna_sequences($locations)

=over 4

=item Parameter and return types

=begin html

<pre>
$locations is a locations
$dna_seqs is a reference to a list where each element is a reference to a list containing 2 items:
	0: a location
	1: a dna
locations is a reference to a list where each element is a location
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
dna is a string

</pre>

=end html

=begin text

$locations is a locations
$dna_seqs is a reference to a list where each element is a reference to a list containing 2 items:
	0: a location
	1: a dna
locations is a reference to a list where each element is a location
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
dna is a string


=end text



=item Description

locations_to_dna_sequences takes as input a list of locations (each in the form of
a list of regions).  The routine constructs 2-tuples composed of

     [the input location,the dna string]

The returned DNA string is formed by concatenating the DNA for each of the
regions that make up the location.

=back

=cut

sub locations_to_dna_sequences
{
    my $self = shift;
    my($locations) = @_;

    my @_bad_arguments;
    (ref($locations) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"locations\" (value was \"$locations\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to locations_to_dna_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'locations_to_dna_sequences');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($dna_seqs);
    #BEGIN locations_to_dna_sequences
    my $kb = $self->{db};
    $dna_seqs = [];
    for my $location (@$locations) {
        my @dnas;
        for my $region (@$location) {
            my $dna = $kb->ComputeDNA(@$region);
            push @dnas, $dna;
        }
        push @$dna_seqs, [$location, join("", @dnas)];
    }
    #END locations_to_dna_sequences
    my @_bad_returns;
    (ref($dna_seqs) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"dna_seqs\" (value was \"$dna_seqs\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to locations_to_dna_sequences:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'locations_to_dna_sequences');
    }
    return($dna_seqs);
}




=head2 proteins_to_fids

  $return = $obj->proteins_to_fids($proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a fids
proteins is a reference to a list where each element is a protein
protein is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a fids
proteins is a reference to a list where each element is a protein
protein is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description

proteins_to_fids takes as input a list of proteins (i.e., a list of md5s) and
returns for each a set of protein-encoding fids that have the designated
sequence as their translation.  That is, for each sequence, the returned fids will
be the entire set (within Kbase) that have the sequence as a translation.

=back

=cut

sub proteins_to_fids
{
    my $self = shift;
    my($proteins) = @_;

    my @_bad_arguments;
    (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"proteins\" (value was \"$proteins\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to proteins_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN proteins_to_fids
    my $kb = $self->{db};
    $return = {};
    for my $id (@$proteins) {
        my @resultRows = $kb->GetFlat("IsProteinFor",
                                      "IsProteinFor(from_link) = ?", [$id],
				     'IsProteinFor(to_link)');
	if (@resultRows != 0) {
                $return->{$id} = \@resultRows;
        }
    }
    #END proteins_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to proteins_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_fids');
    }
    return($return);
}




=head2 proteins_to_protein_families

  $return = $obj->proteins_to_protein_families($proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a protein_families
proteins is a reference to a list where each element is a protein
protein is a string
protein_families is a reference to a list where each element is a protein_family
protein_family is a string

</pre>

=end html

=begin text

$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a protein_families
proteins is a reference to a list where each element is a protein
protein is a string
protein_families is a reference to a list where each element is a protein_family
protein_family is a string


=end text



=item Description

Protein families contain a set of isofunctional homologs.  proteins_to_protein_families
can be used to look up is used to get the set of protein_families containing a specified protein.
For performance reasons, you can submit a batch of proteins (i.e., a list of proteins),
and for each input protein, you get back a set (possibly empty) of protein_families.
Specific collections of families (e.g., FIGfams) usually require that a protein be in
at most one family.  However, we will be integrating protein families from a number of
sources, and so a protein can be in multiple families.

=back

=cut

sub proteins_to_protein_families
{
    my $self = shift;
    my($proteins) = @_;

    my @_bad_arguments;
    (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"proteins\" (value was \"$proteins\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to proteins_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_protein_families');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN proteins_to_protein_families
    my $kb = $self->{db};
    $return = {};
    for my $id (@$proteins) {
        my %famH = map { $_ => 1 } $kb->GetFlat("IsProteinFor IsMemberOf",
                                      "IsProteinFor(from_link) = ?", [$id],
				     'IsMemberOf(to_link)');
        $return->{$id} = [sort keys %famH];
    }
    #END proteins_to_protein_families
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to proteins_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_protein_families');
    }
    return($return);
}




=head2 proteins_to_literature

  $return = $obj->proteins_to_literature($proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a pubrefs
proteins is a reference to a list where each element is a protein
protein is a string
pubrefs is a reference to a list where each element is a pubref
pubref is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: a string

</pre>

=end html

=begin text

$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a pubrefs
proteins is a reference to a list where each element is a protein
protein is a string
pubrefs is a reference to a list where each element is a pubref
pubref is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: a string


=end text



=item Description

The routine proteins_to_literature can be used to extract the list of papers
we have associated with specific protein sequences.  The user should note that
in many cases the association of a paper with a protein sequence is not precise.
That is, the paper may actually describe a closely-related protein (that may
not yet even be in a sequenced genome).  Annotators attempt to use best
judgement when associating literature and proteins.  Publication references
include [pubmed ID,URL for the paper, title of the paper].  In some cases,
the URL and title are omitted.  In theory, we can extract them from PubMed
and we will attempt to do so.

=back

=cut

sub proteins_to_literature
{
    my $self = shift;
    my($proteins) = @_;

    my @_bad_arguments;
    (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"proteins\" (value was \"$proteins\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to proteins_to_literature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_literature');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN proteins_to_literature
    my $kb = $self->{db};
    $return = {};
    for my $id (@$proteins) {
        my @resultRows = $kb->GetAll("IsATopicOf Publication",
                                      "IsATopicOf(from_link) = ?", [$id],
                                      [qw(Publication(id)
                                          Publication(link) Publication(title))]);
	if (@resultRows != 0) {
		$return->{$id} = \@resultRows;
        }
    }

    #END proteins_to_literature
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to proteins_to_literature:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_literature');
    }
    return($return);
}




=head2 proteins_to_functions

  $return = $obj->proteins_to_functions($proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a fid_function_pairs
proteins is a reference to a list where each element is a protein
protein is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
fid is a string
function is a string

</pre>

=end html

=begin text

$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a fid_function_pairs
proteins is a reference to a list where each element is a protein
protein is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
fid is a string
function is a string


=end text



=item Description

The routine proteins_to_functions allows users to access functions associated with
specific protein sequences.  The input proteins are given as a list of MD5 values
(these MD5 values each correspond to a specific protein sequence).  For each input
MD5 value, a list of [feature-id,function] pairs is constructed and returned.
Note that there are many cases in which a single protein sequence corresponds
to the translation associated with multiple protein-encoding genes, and each may
have distinct functions (an undesirable situation, we grant).

This function allows you to access all of the functions assigned (by all annotation
groups represented in Kbase) to each of a set of sequences.

=back

=cut

sub proteins_to_functions
{
    my $self = shift;
    my($proteins) = @_;

    my @_bad_arguments;
    (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"proteins\" (value was \"$proteins\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to proteins_to_functions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_functions');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN proteins_to_functions
    my $kb = $self->{db};
    $return = {};
    for my $id (@$proteins) {
        my @resultRows = $kb->GetAll("IsProteinFor Feature",
                                      "IsProteinFor(from_link) = ?", [$id],
				     [qw(Feature(id) Feature(function))]);
	if (@resultRows != 0) {
                $return->{$id} = \@resultRows;
        }
    }
    #END proteins_to_functions
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to proteins_to_functions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_functions');
    }
    return($return);
}




=head2 proteins_to_roles

  $return = $obj->proteins_to_roles($proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a roles
proteins is a reference to a list where each element is a protein
protein is a string
roles is a reference to a list where each element is a role
role is a string

</pre>

=end html

=begin text

$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a roles
proteins is a reference to a list where each element is a protein
protein is a string
roles is a reference to a list where each element is a role
role is a string


=end text



=item Description

The routine proteins_to_roles allows a user to gather the set of functional
roles that are associated with specifc protein sequences.  A single protein
sequence (designated by an MD5 value) may have numerous associated functions,
since functions are treated as an attribute of the feature, and multiple
features may have precisely the same translation.  In our experience,
it is not uncommon, even for the best annotation teams, to assign
distinct functions (and, hence, functional roles) to identical
protein sequences.

For each input MD5 value, this routine gathers the set of features (fids)
that share the same sequence, collects the associated functions, expands
these into functional roles (for multi-functional proteins), and returns
the set of roles that results.

Note that, if the user wishes to see the specific features that have the
assigned fiunctional roles, they should use proteins_to_functions instead (it
returns the fids associated with each assigned function).

=back

=cut

sub proteins_to_roles
{
    my $self = shift;
    my($proteins) = @_;

    my @_bad_arguments;
    (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"proteins\" (value was \"$proteins\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to proteins_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_roles');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN proteins_to_roles
    my $kb = $self->{db};
    $return = {};
    for my $id (@$proteins) {
        my %roleH = map { $_ => 1 } $kb->GetFlat("IsProteinFor HasFunctional",
                                      "IsProteinFor(from_link) = ?", [$id],
				     'HasFunctional(to_link)');
        $return->{$id} = [sort keys %roleH];
    }
    #END proteins_to_roles
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to proteins_to_roles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'proteins_to_roles');
    }
    return($return);
}




=head2 roles_to_proteins

  $return = $obj->roles_to_proteins($roles)

=over 4

=item Parameter and return types

=begin html

<pre>
$roles is a roles
$return is a reference to a hash where the key is a role and the value is a proteins
roles is a reference to a list where each element is a role
role is a string
proteins is a reference to a list where each element is a protein
protein is a string

</pre>

=end html

=begin text

$roles is a roles
$return is a reference to a hash where the key is a role and the value is a proteins
roles is a reference to a list where each element is a role
role is a string
proteins is a reference to a list where each element is a protein
protein is a string


=end text



=item Description

roles_to_proteins can be used to extract the set of proteins (designated by MD5 values)
that currently are believed to implement a given role.  Note that the proteins
may be multifunctional, meaning that they may be implementing other roles, as well.

=back

=cut

sub roles_to_proteins
{
    my $self = shift;
    my($roles) = @_;

    my @_bad_arguments;
    (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"roles\" (value was \"$roles\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to roles_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_proteins');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN roles_to_proteins
    my $kb = $self->{db};
    $return = {};
    if ((! $roles) || (@$roles == 0)) { return $return }
    for my $role (@$roles) {
        my %roleH = map { $_ => 1 } $kb->GetFlat("IsFunctionalIn Produces",
                                      "IsFunctionalIn(from_link) = ?", [$role],
				     'Produces(to_link)');
        $return->{$role} = [sort keys %roleH];
    }
    #END roles_to_proteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to roles_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_proteins');
    }
    return($return);
}




=head2 roles_to_subsystems

  $return = $obj->roles_to_subsystems($roles)

=over 4

=item Parameter and return types

=begin html

<pre>
$roles is a roles
$return is a reference to a hash where the key is a role and the value is a subsystems
roles is a reference to a list where each element is a role
role is a string
subsystems is a reference to a list where each element is a subsystem
subsystem is a string

</pre>

=end html

=begin text

$roles is a roles
$return is a reference to a hash where the key is a role and the value is a subsystems
roles is a reference to a list where each element is a role
role is a string
subsystems is a reference to a list where each element is a subsystem
subsystem is a string


=end text



=item Description

roles_to_subsystems can be used to access the set of subsystems that include
specific roles. The input is a list of roles (i.e., role descriptions), and a mapping
is returned as a hash with key role description and values composed of sets of susbsystem names.

=back

=cut

sub roles_to_subsystems
{
    my $self = shift;
    my($roles) = @_;

    my @_bad_arguments;
    (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"roles\" (value was \"$roles\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to roles_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_subsystems');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN roles_to_subsystems
    my $kb = $self->{db};
    $return = {};
    if ((! $roles) || (@$roles == 0)) { return $return }

    for my $role (@$roles) {
        my @resultRows = $kb->GetFlat("IsIncludedIn",
                                      "IsIncludedIn(from_link) = ?", [$role],
				     'IsIncludedIn(to_link)');
	if (@resultRows != 0) {
                $return->{$role} = \@resultRows;
        }
    }

    #END roles_to_subsystems
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to roles_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_subsystems');
    }
    return($return);
}




=head2 roles_to_protein_families

  $return = $obj->roles_to_protein_families($roles)

=over 4

=item Parameter and return types

=begin html

<pre>
$roles is a roles
$return is a reference to a hash where the key is a role and the value is a protein_families
roles is a reference to a list where each element is a role
role is a string
protein_families is a reference to a list where each element is a protein_family
protein_family is a string

</pre>

=end html

=begin text

$roles is a roles
$return is a reference to a hash where the key is a role and the value is a protein_families
roles is a reference to a list where each element is a role
role is a string
protein_families is a reference to a list where each element is a protein_family
protein_family is a string


=end text



=item Description

roles_to_protein_families can be used to locate the protein families containing
features that have assigned functions implying that they implement designated roles.
Note that for any input role (given as a role description), you may have a set
of distinct protein_families returned.

=back

=cut

sub roles_to_protein_families
{
    my $self = shift;
    my($roles) = @_;

    my @_bad_arguments;
    (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"roles\" (value was \"$roles\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to roles_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_protein_families');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN roles_to_protein_families
    my $kb = $self->{db};
    $return = {};
    if ((! $roles) || (@$roles == 0)) { return $return }
    for my $role (@$roles) {
        my @resultRows = $kb->GetFlat("DeterminesFunctionOf",
                                      "DeterminesFunctionOf(from_link) = ?", [$role],
				     'DeterminesFunctionOf(to_link)');
	if (@resultRows != 0) {
                $return->{$role} = \@resultRows;
        }
    }

    #END roles_to_protein_families
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to roles_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_protein_families');
    }
    return($return);
}




=head2 fids_to_coexpressed_fids

  $return = $obj->fids_to_coexpressed_fids($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a scored_fids
fids is a reference to a list where each element is a fid
fid is a string
scored_fids is a reference to a list where each element is a scored_fid
scored_fid is a reference to a list containing 2 items:
	0: a fid
	1: a float

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a scored_fids
fids is a reference to a list where each element is a fid
fid is a string
scored_fids is a reference to a list where each element is a scored_fid
scored_fid is a reference to a list containing 2 items:
	0: a fid
	1: a float


=end text



=item Description

The routine fids_to_coexpressed_fids returns (for each input fid) a
list of features that appear to be coexpressed.  That is,
for an input fid, we determine the set of fids from the same genome that
have Pearson Correlation Coefficients (based on normalized expression data)
greater than 0.5 or less than -0.5.

=back

=cut

sub fids_to_coexpressed_fids
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_coexpressed_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_coexpressed_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_coexpressed_fids
    $return = {};
    if (@$fids < 1)  { return $return }

    my $kb = $self->{db};

    my $n = @$fids;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $fid_constraint = "IsCoregulatedWith(from_link) IN $targets";

    my @res = $kb->GetAll('IsCoregulatedWith',
			  $fid_constraint,
			  $fids,
			  'IsCoregulatedWith(from_link) IsCoregulatedWith(to_link) IsCoregulatedWith(coefficient)');

    foreach my $tuple (@res)
    {
	my($fid1,$fid2,$pcc) = @$tuple;
	$pcc = sprintf("%0.3f",$pcc);
	push(@{$return->{$fid1}},[$fid2,$pcc]);
    }

    #END fids_to_coexpressed_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_coexpressed_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_coexpressed_fids');
    }
    return($return);
}




=head2 protein_families_to_fids

  $return = $obj->protein_families_to_fids($protein_families)

=over 4

=item Parameter and return types

=begin html

<pre>
$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a fids
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a fids
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description

protein_families_to_fids can be used to access the set of fids represented by each of
a set of protein_families.  We define protein_families as sets of fids (rather than sets
of MD5s.  This may, or may not, be a mistake.

=back

=cut

sub protein_families_to_fids
{
    my $self = shift;
    my($protein_families) = @_;

    my @_bad_arguments;
    (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"protein_families\" (value was \"$protein_families\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to protein_families_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN protein_families_to_fids
    my $kb = $self->{db};
    $return = {};
    for my $id (@$protein_families) {
        my @resultRows = $kb->GetFlat("HasMember",
                                      "HasMember(from_link) = ?", [$id],
				     'HasMember(to_link)');
	if (@resultRows != 0) {
                $return->{$id} = \@resultRows;
        }
    }
    #END protein_families_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to protein_families_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_fids');
    }
    return($return);
}




=head2 protein_families_to_proteins

  $return = $obj->protein_families_to_proteins($protein_families)

=over 4

=item Parameter and return types

=begin html

<pre>
$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a proteins
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
proteins is a reference to a list where each element is a protein
protein is a string

</pre>

=end html

=begin text

$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a proteins
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
proteins is a reference to a list where each element is a protein
protein is a string


=end text



=item Description

protein_families_to_proteins can be used to access the set of proteins (i.e., the set of MD5 values)
represented by each of a set of protein_families.  We define protein_families as sets of fids (rather than sets
           of MD5s.  This may, or may not, be a mistake.

=back

=cut

sub protein_families_to_proteins
{
    my $self = shift;
    my($protein_families) = @_;

    my @_bad_arguments;
    (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"protein_families\" (value was \"$protein_families\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to protein_families_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_proteins');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN protein_families_to_proteins
    my $kb = $self->{db};
    $return = {};
    for my $id (@$protein_families) {
        my %protH = map { $_ => 1 } $kb->GetFlat("HasMember Produces",
                                      "HasMember(from_link) = ?", [$id],
				     'Produces(to_link)');
        $return->{$id} = [sort keys %protH];
    }
    #END protein_families_to_proteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to protein_families_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_proteins');
    }
    return($return);
}




=head2 protein_families_to_functions

  $return = $obj->protein_families_to_functions($protein_families)

=over 4

=item Parameter and return types

=begin html

<pre>
$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a function
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
function is a string

</pre>

=end html

=begin text

$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a function
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
function is a string


=end text



=item Description

protein_families_to_functions can be used to extract the set of functions assigned to the fids
that make up the family.  Each input protein_family is mapped to a family function.

=back

=cut

sub protein_families_to_functions
{
    my $self = shift;
    my($protein_families) = @_;

    my @_bad_arguments;
    (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"protein_families\" (value was \"$protein_families\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to protein_families_to_functions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_functions');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN protein_families_to_functions
    my $kb = $self->{db};
    $return = {};
    my $n = @$protein_families;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $constraint = "Family(id) IN $targets";

    my @res = $kb->GetAll('Family',
			  $constraint,
			  $protein_families,
			  'Family(id) Family(family_function)');

    foreach my $tuple (@res)
    {
	my($ff,$func) = @$tuple;
	$return->{$ff} = $func;
    }
    #END protein_families_to_functions
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to protein_families_to_functions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_functions');
    }
    return($return);
}




=head2 protein_families_to_co_occurring_families

  $return = $obj->protein_families_to_co_occurring_families($protein_families)

=over 4

=item Parameter and return types

=begin html

<pre>
$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a fc_protein_families
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
fc_protein_families is a reference to a list where each element is a fc_protein_family
fc_protein_family is a reference to a list containing 3 items:
	0: a protein_family
	1: a score
	2: a function
score is a float
function is a string

</pre>

=end html

=begin text

$protein_families is a protein_families
$return is a reference to a hash where the key is a protein_family and the value is a fc_protein_families
protein_families is a reference to a list where each element is a protein_family
protein_family is a string
fc_protein_families is a reference to a list where each element is a fc_protein_family
fc_protein_family is a reference to a list containing 3 items:
	0: a protein_family
	1: a score
	2: a function
score is a float
function is a string


=end text



=item Description

Since we accumulate data relating to the co-occurrence (i.e., chromosomal
clustering) of genes in prokaryotic genomes,  we can note which pairs of genes tend to co-occur.
From this data, one can compute the protein families that tend to co-occur (i.e., tend to
cluster on the chromosome).  This allows one to formulate conjectures for unclustered pairs, based
on clustered pairs from the same protein_families.

=back

=cut

sub protein_families_to_co_occurring_families
{
    my $self = shift;
    my($protein_families) = @_;

    my @_bad_arguments;
    (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"protein_families\" (value was \"$protein_families\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to protein_families_to_co_occurring_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_co_occurring_families');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN protein_families_to_co_occurring_families
    my $kb = $self->{db};
    $return = {};

    my $n = @$protein_families;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $constraint = "IsCoupledTo(from_link) IN $targets";
    my @res = $kb->GetAll('IsCoupledTo Family',
			  $constraint,
			  $protein_families,
			  'IsCoupledTo(from_link) IsCoupledTo(to_link) IsCoupledTo(co_occurrence_evidence) Family(family_function)');

    foreach my $tuple (grep { $_->[0] ne $_->[1] } @res)
    {
	my($from,$to,$sc,$func) = @$tuple;
	if ($sc >= 10)
	{
	    push(@{$return->{$from}},[$to,$sc,$func]);
	}
    }
    #END protein_families_to_co_occurring_families
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to protein_families_to_co_occurring_families:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'protein_families_to_co_occurring_families');
    }
    return($return);
}




=head2 co_occurrence_evidence

  $return = $obj->co_occurrence_evidence($pairs_of_fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$pairs_of_fids is a pairs_of_fids
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: a pair_of_fids
	1: an evidence
pairs_of_fids is a reference to a list where each element is a pair_of_fids
pair_of_fids is a reference to a list containing 2 items:
	0: a fid
	1: a fid
fid is a string
evidence is a reference to a list where each element is a pair_of_fids

</pre>

=end html

=begin text

$pairs_of_fids is a pairs_of_fids
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: a pair_of_fids
	1: an evidence
pairs_of_fids is a reference to a list where each element is a pair_of_fids
pair_of_fids is a reference to a list containing 2 items:
	0: a fid
	1: a fid
fid is a string
evidence is a reference to a list where each element is a pair_of_fids


=end text



=item Description

co-occurence_evidence is used to retrieve the detailed pairs of genes that go into the
computation of co-occurence scores.  The scores reflect an estimate of the number of distinct OTUs that
contain an instance of a co-occuring pair.  This routine returns as evidence a list of all the pairs that
went into the computation.

The input to the computation is a list of pairs for which evidence is desired.

The returned output is a list of elements. one for each input pair.  Each output element
is a 2-tuple: the input pair and the evidence for the pair.  The evidence is a list of pairs of
fids that are believed to correspond to the input pair.

=back

=cut

sub co_occurrence_evidence
{
    my $self = shift;
    my($pairs_of_fids) = @_;

    my @_bad_arguments;
    (ref($pairs_of_fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"pairs_of_fids\" (value was \"$pairs_of_fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to co_occurrence_evidence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'co_occurrence_evidence');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN co_occurrence_evidence
    my $kb = $self->{db};
    for my $pair (@$pairs_of_fids) {
	my($fid1,$fid2) = @$pair;
	my $flipped = ($fid1 gt $fid2) ? 1 : 0;
	my $pair_key = join(":",sort @$pair);
        my @resultRows = $kb->GetAll("Determines PairSet IsDeterminedBy",
				     'Determines(from_link) = ?',[$pair_key],
				     [qw(Determines(inverted) IsDeterminedBy(inverted) IsDeterminedBy(to_link))]);

	if (@resultRows != 0) {
		my @ev;
		foreach $_ (@resultRows)
		{
		    my($flip1,$flip2,$to_pair) = @$_;
		    my $must_flip = ($flipped + $flip1 + $flip2) % 2;
		    my @to = split(":",$to_pair);
		    if ($must_flip) { @to = reverse @to }
		    push(@ev,\@to);
		}
		push(@$return,[$pair,\@ev]);
        }
    }
    #END co_occurrence_evidence
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to co_occurrence_evidence:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'co_occurrence_evidence');
    }
    return($return);
}




=head2 contigs_to_sequences

  $return = $obj->contigs_to_sequences($contigs)

=over 4

=item Parameter and return types

=begin html

<pre>
$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a dna
contigs is a reference to a list where each element is a contig
contig is a string
dna is a string

</pre>

=end html

=begin text

$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a dna
contigs is a reference to a list where each element is a contig
contig is a string
dna is a string


=end text



=item Description

contigs_to_sequences is used to access the DNA sequence associated with each of a set
of input contigs.  It takes as input a set of contig IDs (from which the genome can be determined) and
produces a mapping from the input IDs to the returned DNA sequence in each case.

=back

=cut

sub contigs_to_sequences
{
    my $self = shift;
    my($contigs) = @_;

    my @_bad_arguments;
    (ref($contigs) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"contigs\" (value was \"$contigs\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to contigs_to_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'contigs_to_sequences');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN contigs_to_sequences
    my $kb = $self->{db};
    $return = {};
    for my $contig ( @$contigs ) {
        my @dna = $kb->GetFlat("HasAsSequence HasSection ContigChunk",
            'HasAsSequence(from_link) = ?', [$contig], 'ContigChunk(sequence)');
        $return->{$contig} = join("", @dna);
    }
    #END contigs_to_sequences
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to contigs_to_sequences:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'contigs_to_sequences');
    }
    return($return);
}




=head2 contigs_to_lengths

  $return = $obj->contigs_to_lengths($contigs)

=over 4

=item Parameter and return types

=begin html

<pre>
$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a length
contigs is a reference to a list where each element is a contig
contig is a string
length is an int

</pre>

=end html

=begin text

$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a length
contigs is a reference to a list where each element is a contig
contig is a string
length is an int


=end text



=item Description

In some cases, one wishes to know just the lengths of the contigs, rather than their
actual DNA sequence (e.g., suppose that you wished to know if a gene boundary occured within
100 bp of the end of the contig).  To avoid requiring a user to access the entire DNA sequence,
we offer the ability to retrieve just the contig lengths.  Input to the routine is a list of contig IDs.
The routine returns a mapping from contig IDs to lengths

=back

=cut

sub contigs_to_lengths
{
    my $self = shift;
    my($contigs) = @_;

    my @_bad_arguments;
    (ref($contigs) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"contigs\" (value was \"$contigs\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to contigs_to_lengths:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'contigs_to_lengths');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN contigs_to_lengths
    my $kb = $self->{db};
    $return = {};
    for my $contig ( @$contigs ) {
        my ($len) = $kb->GetFlat("HasAsSequence ContigSequence",
            'HasAsSequence(from_link) = ?', [$contig], 'ContigSequence(length)');
        $return->{$contig} = $len;
    }
    #END contigs_to_lengths
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to contigs_to_lengths:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'contigs_to_lengths');
    }
    return($return);
}




=head2 contigs_to_md5s

  $return = $obj->contigs_to_md5s($contigs)

=over 4

=item Parameter and return types

=begin html

<pre>
$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a md5
contigs is a reference to a list where each element is a contig
contig is a string
md5 is a string

</pre>

=end html

=begin text

$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a md5
contigs is a reference to a list where each element is a contig
contig is a string
md5 is a string


=end text



=item Description

contigs_to_md5s can be used to acquire MD5 values for each of a list of contigs.
The quickest way to determine whether two contigs are identical is to compare their
associated MD5 values, eliminating the need to retrieve the sequence of each and compare them.

The routine takes as input a list of contig IDs.  The output is a mapping
from contig ID to MD5 value.

=back

=cut

sub contigs_to_md5s
{
    my $self = shift;
    my($contigs) = @_;

    my @_bad_arguments;
    (ref($contigs) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"contigs\" (value was \"$contigs\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to contigs_to_md5s:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'contigs_to_md5s');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN contigs_to_md5s
    my $kb = $self->{db};
    $return = {};
    for my $contig (@$contigs) {
        my ($md5) = $kb->GetFlat("HasAsSequence", 'HasAsSequence(from_link) = ?',
            [$contig], 'to-link');
        $return->{$contig} = $md5;
    }
    #END contigs_to_md5s
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to contigs_to_md5s:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'contigs_to_md5s');
    }
    return($return);
}




=head2 md5s_to_genomes

  $return = $obj->md5s_to_genomes($md5s)

=over 4

=item Parameter and return types

=begin html

<pre>
$md5s is a md5s
$return is a reference to a hash where the key is a md5 and the value is a genomes
md5s is a reference to a list where each element is a md5
md5 is a string
genomes is a reference to a list where each element is a genome
genome is a string

</pre>

=end html

=begin text

$md5s is a md5s
$return is a reference to a hash where the key is a md5 and the value is a genomes
md5s is a reference to a list where each element is a md5
md5 is a string
genomes is a reference to a list where each element is a genome
genome is a string


=end text



=item Description

md5s to genomes is used to get the genomes associated with each of a list of input md5 values.

           The routine takes as input a list of MD5 values.  It constructs a mapping from each input
           MD5 value to a list of genomes that share the same MD5 value.

           The MD5 value for a genome is independent of the names of contigs and the case of the DNA sequence
           data.

=back

=cut

sub md5s_to_genomes
{
    my $self = shift;
    my($md5s) = @_;

    my @_bad_arguments;
    (ref($md5s) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"md5s\" (value was \"$md5s\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to md5s_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'md5s_to_genomes');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN md5s_to_genomes
    $return = {};
    my $kb = $self->{db};
    for my $md5 (@$md5s) {
        my @genomes = $kb->GetFlat('Genome', 'Genome(md5) = ?', [$md5],
                'id');
        $return->{$md5} = \@genomes;
    }
    #END md5s_to_genomes
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to md5s_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'md5s_to_genomes');
    }
    return($return);
}




=head2 genomes_to_md5s

  $return = $obj->genomes_to_md5s($genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a md5
genomes is a reference to a list where each element is a genome
genome is a string
md5 is a string

</pre>

=end html

=begin text

$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a md5
genomes is a reference to a list where each element is a genome
genome is a string
md5 is a string


=end text



=item Description

The routine genomes_to_md5s can be used to look up the MD5 value associated with each of
a set of genomes.  The MD5 values are computed when the genome is loaded, so this routine
just retrieves the precomputed values.

Note that the MD5 value of a genome is independent of the contig names and case of the
DNA sequences that make up the genome.

=back

=cut

sub genomes_to_md5s
{
    my $self = shift;
    my($genomes) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomes_to_md5s:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_md5s');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN genomes_to_md5s
    $return = {};
    my $kb = $self->{db};
    for my $genome (@$genomes) {
        my ($md5) = $kb->GetFlat('Genome', 'Genome(id) = ?', [$genome],
            'md5');
        $return->{$genome} = $md5;
    }
    #END genomes_to_md5s
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomes_to_md5s:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_md5s');
    }
    return($return);
}




=head2 genomes_to_contigs

  $return = $obj->genomes_to_contigs($genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a contigs
genomes is a reference to a list where each element is a genome
genome is a string
contigs is a reference to a list where each element is a contig
contig is a string

</pre>

=end html

=begin text

$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a contigs
genomes is a reference to a list where each element is a genome
genome is a string
contigs is a reference to a list where each element is a contig
contig is a string


=end text



=item Description

The routine genomes_to_con`tigs can be used to retrieve the IDs of the contigs
associated with each of a list of input genomes.  The routine constructs a mapping
from genome ID to the list of contigs included in the genome.

=back

=cut

sub genomes_to_contigs
{
    my $self = shift;
    my($genomes) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomes_to_contigs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_contigs');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN genomes_to_contigs
    $return = {};
    my $kb = $self->{db};
    for my $genome (@$genomes) {
        my @contigs = $kb->GetFlat('IsComposedOf', 'IsComposedOf(from_link) = ?', [$genome],
            'to-link');
        $return->{$genome} = \@contigs;
    }
    #END genomes_to_contigs
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomes_to_contigs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_contigs');
    }
    return($return);
}




=head2 genomes_to_fids

  $return = $obj->genomes_to_fids($genomes, $types_of_fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$types_of_fids is a types_of_fids
$return is a reference to a hash where the key is a genome and the value is a fids
genomes is a reference to a list where each element is a genome
genome is a string
types_of_fids is a reference to a list where each element is a type_of_fid
type_of_fid is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$genomes is a genomes
$types_of_fids is a types_of_fids
$return is a reference to a hash where the key is a genome and the value is a fids
genomes is a reference to a list where each element is a genome
genome is a string
types_of_fids is a reference to a list where each element is a type_of_fid
type_of_fid is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description

genomes_to_fids is used to get the fids included in specific genomes.  It
is often the case that you want just one or two types of fids -- hence, the
types_of_fids argument.

=back

=cut

sub genomes_to_fids
{
    my $self = shift;
    my($genomes, $types_of_fids) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    (ref($types_of_fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"types_of_fids\" (value was \"$types_of_fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomes_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN genomes_to_fids
    $return = {};
    my $kb = $self->{db};
    my (@marks, @parms);
    for my $type (@$types_of_fids) {
        push @marks, "?";
    }
    my $filter;
    if (! @marks) {
        $filter = "IsOwnerOf(from_link) = ?";
    } elsif (@marks == 1) {
        $filter = "Feature(feature_type) = ? AND IsOwnerOf(from_link) = ?";
        push @parms, $types_of_fids->[0];
    } else {
        $filter = "Feature(feature_type) IN (" . join(", ", @marks) .
                ") AND IsOwnerOf(from_link) = ?";
        push @parms, @$types_of_fids;
    }
    for my $genome (@$genomes) {
         my @fids = $kb->GetFlat('IsOwnerOf Feature', $filter,
                [@parms, $genome], 'Feature(id)');
        $return->{$genome} = \@fids;
    }
    #END genomes_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomes_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_fids');
    }
    return($return);
}




=head2 genomes_to_taxonomies

  $return = $obj->genomes_to_taxonomies($genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a taxonomic_groups
genomes is a reference to a list where each element is a genome
genome is a string
taxonomic_groups is a reference to a list where each element is a taxonomic_group
taxonomic_group is a string

</pre>

=end html

=begin text

$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a taxonomic_groups
genomes is a reference to a list where each element is a genome
genome is a string
taxonomic_groups is a reference to a list where each element is a taxonomic_group
taxonomic_group is a string


=end text



=item Description

The routine genomes_to_taxonomies can be used to retrieve taxonomic information for
each of a list of input genomes.  For each genome in the input list of genomes, a list of
taxonomic groups is returned.  Kbase will use the groups maintained by NCBI.  For an NCBI
taxonomic string like

     cellular organisms;
     Bacteria;
     Proteobacteria;
     Gammaproteobacteria;
     Enterobacteriales;
     Enterobacteriaceae;
     Escherichia;
     Escherichia coli

associated with the strain 'Escherichia coli 1412', this routine would return a list of these
taxonomic groups:


     ['Bacteria',
      'Proteobacteria',
      'Gammaproteobacteria',
      'Enterobacteriales',
      'Enterobacteriaceae',
      'Escherichia',
      'Escherichia coli',
      'Escherichia coli 1412'
     ]

That is, the initial "cellular organisms" has been deleted, and the strain ID has
been added as the last "grouping".

The output is a mapping from genome IDs to lists of the form shown above.

=back

=cut

sub genomes_to_taxonomies
{
    my $self = shift;
    my($genomes) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomes_to_taxonomies:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_taxonomies');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN genomes_to_taxonomies
    my $kb = $self->{db};
    $return = {};
    my $fields = 'TaxonomicGrouping(scientific_name) TaxonomicGrouping(id) TaxonomicGrouping(hidden) TaxonomicGrouping(domain)';
    for my $genome (@$genomes) {
        my ($taxa) = $kb->GetAll('IsInTaxa TaxonomicGrouping', 'IsInTaxa(from_link) = ?',
                [$genome], $fields);
        if (defined $taxa) {
            my @taxonomy = ($taxa->[0]);
            while (! $taxa->[3]) {
                ($taxa) = $kb->GetAll('IsInGroup TaxonomicGrouping', 'IsInGroup(from_link) = ?',
                        [$taxa->[1]], $fields);
                if (! $taxa->[2]) {
                    unshift @taxonomy, $taxa->[0];
                }
            }
            $return->{$genome} = \@taxonomy;
        }
    }
    #END genomes_to_taxonomies
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomes_to_taxonomies:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_taxonomies');
    }
    return($return);
}




=head2 genomes_to_subsystems

  $return = $obj->genomes_to_subsystems($genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a variant_subsystem_pairs
genomes is a reference to a list where each element is a genome
genome is a string
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string

</pre>

=end html

=begin text

$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a variant_subsystem_pairs
genomes is a reference to a list where each element is a genome
genome is a string
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string


=end text



=item Description

A user can invoke genomes_to_subsystems to rerieve the names of the subsystems
relevant to each genome.  The input is a list of genomes.  The output is a mapping
from genome to a list of 2-tuples, where each 2-tuple give a variant code and a
subsystem name.  Variant codes of -1 (or *-1) amount to assertions that the
genome contains no active variant.  A variant code of 0 means "work in progress",
and presence or absence of the subsystem in the genome should be undetermined.

=back

=cut

sub genomes_to_subsystems
{
    my $self = shift;
    my($genomes) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomes_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_subsystems');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN genomes_to_subsystems
    $return = {};
    my $kb = $self->{db};
    for my $genome (@$genomes) {
        my @subs = $kb->GetAll('Uses Implements Variant IsDescribedBy', 'Uses(from_link) = ?', [$genome],
            ['Variant(code)', 'IsDescribedBy(to_link)']);
        $return->{$genome} = \@subs;
    }
    #END genomes_to_subsystems
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomes_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_subsystems');
    }
    return($return);
}




=head2 subsystems_to_genomes

  $return = $obj->subsystems_to_genomes($subsystems)

=over 4

=item Parameter and return types

=begin html

<pre>
$subsystems is a subsystems
$return is a reference to a hash where the key is a subsystem and the value is a reference to a list where each element is a reference to a list containing 2 items:
	0: a variant
	1: a genome
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
variant is a string
genome is a string

</pre>

=end html

=begin text

$subsystems is a subsystems
$return is a reference to a hash where the key is a subsystem and the value is a reference to a list where each element is a reference to a list containing 2 items:
	0: a variant
	1: a genome
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
variant is a string
genome is a string


=end text



=item Description

The routine subsystems_to_genomes is used to determine which genomes are in
specified subsystems.  The input is the list of subsystem names of interest.
The output is a map from the subsystem names to lists of 2-tuples, where each 2-tuple is
a [variant-code,genome ID] pair.

=back

=cut

sub subsystems_to_genomes
{
    my $self = shift;
    my($subsystems) = @_;

    my @_bad_arguments;
    (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"subsystems\" (value was \"$subsystems\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to subsystems_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_genomes');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN subsystems_to_genomes
    $return = {};
    my $kb = $self->{db};
    for my $subsystem (@$subsystems) {
        my @genomes = $kb->GetAll('Describes Variant IsImplementedBy IsUsedBy', 'Describes(from_link) = ?', [$subsystem],
            ['Variant(code)', 'IsUsedBy(to_link)']);
        $return->{$subsystem} = \@genomes;
    }
    #END subsystems_to_genomes
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to subsystems_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_genomes');
    }
    return($return);
}




=head2 subsystems_to_fids

  $return = $obj->subsystems_to_fids($subsystems, $genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$subsystems is a subsystems
$genomes is a genomes
$return is a reference to a hash where the key is a subsystem and the value is a reference to a hash where the key is a genome and the value is a reference to a list containing 2 items:
	0: a variant
	1: a fids
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
genomes is a reference to a list where each element is a genome
genome is a string
variant is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$subsystems is a subsystems
$genomes is a genomes
$return is a reference to a hash where the key is a subsystem and the value is a reference to a hash where the key is a genome and the value is a reference to a list containing 2 items:
	0: a variant
	1: a fids
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
genomes is a reference to a list where each element is a genome
genome is a string
variant is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description

The routine subsystems_to_fids allows the user to map subsystem names into the fids that
occur in genomes in the subsystems.  Specifically, the input is a list of subsystem names.
What is returned is a mapping from subsystem names to a "genome-mapping".  The genome-mapping
takes genome IDs to 2-tuples that capture the variant code of the genome and the fids from
the genome that are included in the subsystem.

=back

=cut

sub subsystems_to_fids
{
    my $self = shift;
    my($subsystems, $genomes) = @_;

    my @_bad_arguments;
    (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"subsystems\" (value was \"$subsystems\")");
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to subsystems_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN subsystems_to_fids
    $return = {};
    my $kb = $self->{db};
    my @filters;
    my @parms;
    if (! $genomes) {
        $genomes = [];
    }
    if (@$genomes == 1) {
        push @filters, "IsOwnedBy(to_link) = ?";
        push @parms, $genomes->[0];
    } elsif (@$genomes > 1) {
        push @filters, "IsOwnedBy(to_link) IN (" . join(", ", ('?') x scalar(@$genomes)) . ")";
        push @parms, @$genomes;
    }
    push @filters, 'Describes(from_link) = ?';
    my $filter = join(" AND ", @filters);
    for my $subsystem (@$subsystems) {
        my @fidData = $kb->GetAll('Describes Variant IsImplementedBy IsRowOf Contains IsOwnedBy',
                $filter, [@parms, $subsystem], ['IsImplementedBy(to_link)',
                'IsOwnedBy(to_link)', 'Variant(code)', 'Contains(to_link)']);
        my %rowSpecs;
        my %rowFids;
#print STDERR Dumper @fidData, "FIDDATA\n";
        for my $fidDatum (@fidData) {
            my ($rowID, $genome, $variant, $fid) = @$fidDatum;
            if (! $rowSpecs{$rowID}) {
                $rowSpecs{$rowID} = [$genome, $variant];
            }
            push @{$rowFids{$rowID}}, $fid;
        }
        my %genomes;
        for my $rowID (keys %rowSpecs) {
            my ($genome, $variant) = @{$rowSpecs{$rowID}};
            push @{$genomes{$genome}}, [$variant, $rowFids{$rowID}];
        }
        $return->{$subsystem} = \%genomes;
    }
    #END subsystems_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to subsystems_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_fids');
    }
    return($return);
}




=head2 subsystems_to_roles

  $return = $obj->subsystems_to_roles($subsystems, $aux)

=over 4

=item Parameter and return types

=begin html

<pre>
$subsystems is a subsystems
$aux is an aux
$return is a reference to a hash where the key is a subsystem and the value is a roles
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
aux is an int
roles is a reference to a list where each element is a role
role is a string

</pre>

=end html

=begin text

$subsystems is a subsystems
$aux is an aux
$return is a reference to a hash where the key is a subsystem and the value is a roles
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
aux is an int
roles is a reference to a list where each element is a role
role is a string


=end text



=item Description

The routine subsystem_to_roles is used to determine the role descriptions that
occur in a subsystem.  The input is a list of subsystem names.  A map is returned connecting
subsystem names to lists of roles.  'aux' is a boolean variable.  If it is 0, auxiliary roles
are not returned.  If it is 1, they are returned.

=back

=cut

sub subsystems_to_roles
{
    my $self = shift;
    my($subsystems, $aux) = @_;

    my @_bad_arguments;
    (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"subsystems\" (value was \"$subsystems\")");
    (!ref($aux)) or push(@_bad_arguments, "Invalid type for argument \"aux\" (value was \"$aux\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to subsystems_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_roles');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN subsystems_to_roles
    $return = {};
    my $kb = $self->{db};
    for my $subsystem (@$subsystems) {

	my @filter;
	my @params;
	push(@filter, 'Includes(from_link) = ?');
	push(@params, $subsystem);
	if (!$aux)
	{
	    push(@filter, 'Includes(auxiliary) = ?');
	    push(@params, '0');
	}

        my @roles = $kb->GetFlat('Includes',
				 join(' AND ', @filter),
				 \@params,
				 'Includes(to_link)');
        $return->{$subsystem} = \@roles;
    }
    #END subsystems_to_roles
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to subsystems_to_roles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_roles');
    }
    return($return);
}




=head2 subsystems_to_spreadsheets

  $return = $obj->subsystems_to_spreadsheets($subsystems, $genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$subsystems is a subsystems
$genomes is a genomes
$return is a reference to a hash where the key is a subsystem and the value is a reference to a hash where the key is a genome and the value is a row
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
genomes is a reference to a list where each element is a genome
genome is a string
row is a reference to a list containing 2 items:
	0: a variant
	1: a reference to a hash where the key is a role and the value is a fids
variant is a string
role is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$subsystems is a subsystems
$genomes is a genomes
$return is a reference to a hash where the key is a subsystem and the value is a reference to a hash where the key is a genome and the value is a row
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
genomes is a reference to a list where each element is a genome
genome is a string
row is a reference to a list containing 2 items:
	0: a variant
	1: a reference to a hash where the key is a role and the value is a fids
variant is a string
role is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description

The subsystem_to_spreadsheet routine allows a user to extract the subsystem spreadsheets for
a specified set of subsystem names.  In the returned output, each subsystem is mapped
to a hash that takes as input a genome ID and maps it to the "row" for the genome in the subsystem.
The "row" is itself a 2-tuple composed of the variant code, and a mapping from role descriptions to
lists of fids.  We suggest writing a simple test script to get, say, the subsystem named
'Histidine Degradation', extracting the spreadsheet, and then using something like Dumper to make
sure that it all makes sense.

=back

=cut

sub subsystems_to_spreadsheets
{
    my $self = shift;
    my($subsystems, $genomes) = @_;

    my @_bad_arguments;
    (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"subsystems\" (value was \"$subsystems\")");
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to subsystems_to_spreadsheets:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_spreadsheets');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN subsystems_to_spreadsheets
    $return = {};
    if (! $genomes) {
        $genomes = [];
    }
    my $filter;
    if (@$genomes) {
        $filter = "Describes(from_link) = ? AND IsUsedBy(to_link) IN (" .
            join(", ", ('?') x scalar(@$genomes)) . ")";
    } else {
        $filter = "Describes(from_link) = ?";
    }
    my $kb = $self->{db};
    for my $subsystem (@$subsystems) {
        my %sheet;
        my $rowQ = $kb->Get('Describes Variant IsImplementedBy SSRow IsUsedBy',
            $filter, [$subsystem, @$genomes]);
        while (my $rowData = $rowQ->Fetch()) {
            my $rowID = $rowData->PrimaryValue('IsUsedBy(from_link)');
            my $variantCode = $rowData->PrimaryValue('Variant(code)');
            my $genome = $rowData->PrimaryValue('IsUsedBy(to_link)');
            my %row;
            my @cellData = $kb->GetAll('IsRowOf SSCell HasRole AND SSCell Contains',
                'IsRowOf(from_link) = ?', [$rowID],
                ['HasRole(to_link)', 'Contains(to_link)']);
            for my $cellItem (@cellData) {
                my ($role, $fid) = @$cellItem;
                push @{$row{$role}}, $fid;
            }
	    $sheet{$genome} =[$variantCode, \%row];
        }
        $return->{$subsystem} = \%sheet;
    }
    #END subsystems_to_spreadsheets
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to subsystems_to_spreadsheets:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'subsystems_to_spreadsheets');
    }
    return($return);
}




=head2 all_roles_used_in_models

  $return = $obj->all_roles_used_in_models()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a roles
roles is a reference to a list where each element is a role
role is a string

</pre>

=end html

=begin text

$return is a roles
roles is a reference to a list where each element is a role
role is a string


=end text



=item Description

The all_roles_used_in_models allows a user to access the set of roles that are included in current models.  This is
important.  There are far fewer roles used in models than overall.  Hence, the returned set represents
the minimal set we need to clean up in order to properly support modeling.

=back

=cut

sub all_roles_used_in_models
{
    my $self = shift;

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN all_roles_used_in_models
    my $kb = $self->{db};
    $return = [];
    my @res = $kb->GetAll('IsTriggeredBy',
			  '',
			  [],
			  'IsTriggeredBy(to_link)');

    my %roles;
    foreach my $tuple (@res)
    {
	$roles{$tuple->[0]} = 1;
    }
    my @tmp = sort keys(%roles);
    $return = \@tmp;
    #END all_roles_used_in_models
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to all_roles_used_in_models:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'all_roles_used_in_models');
    }
    return($return);
}




=head2 complexes_to_complex_data

  $return = $obj->complexes_to_complex_data($complexes)

=over 4

=item Parameter and return types

=begin html

<pre>
$complexes is a complexes
$return is a reference to a hash where the key is a complex and the value is a complex_data
complexes is a reference to a list where each element is a complex
complex is a string
complex_data is a reference to a hash where the following keys are defined:
	complex_name has a value which is a name
	complex_roles has a value which is a roles_with_flags
	complex_reactions has a value which is a reactions
name is a string
roles_with_flags is a reference to a list where each element is a role_with_flag
role_with_flag is a reference to a list containing 2 items:
	0: a role
	1: an optional
role is a string
optional is a string
reactions is a reference to a list where each element is a reaction
reaction is a string

</pre>

=end html

=begin text

$complexes is a complexes
$return is a reference to a hash where the key is a complex and the value is a complex_data
complexes is a reference to a list where each element is a complex
complex is a string
complex_data is a reference to a hash where the following keys are defined:
	complex_name has a value which is a name
	complex_roles has a value which is a roles_with_flags
	complex_reactions has a value which is a reactions
name is a string
roles_with_flags is a reference to a list where each element is a role_with_flag
role_with_flag is a reference to a list containing 2 items:
	0: a role
	1: an optional
role is a string
optional is a string
reactions is a reference to a list where each element is a reaction
reaction is a string


=end text



=item Description



=back

=cut

sub complexes_to_complex_data
{
    my $self = shift;
    my($complexes) = @_;

    my @_bad_arguments;
    (ref($complexes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"complexes\" (value was \"$complexes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to complexes_to_complex_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'complexes_to_complex_data');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN complexes_to_complex_data
    $return = {};
    if (@$complexes < 1)  { return $return }

    my $kb = $self->{db};

    my $n = @$complexes;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $complex_constraint = "Complex(id) IN $targets";

    my %to_name;
    my %to_roles;
    my %to_reactions;
    my @res = $kb->GetAll('Complex', $complex_constraint, $complexes,'Complex(id) Complex(name)');
    foreach my $tuple (@res)
    {
	my($cid,$complex_name) = @$tuple;
	$to_name{$cid} = $complex_name;
    }
    @res    = $kb->GetAll('Complex HasStep ReactionRule IsUseOf',
			  $complex_constraint,
			  $complexes,
			  'Complex(id) IsUseOf(to_link)');

    foreach my $tuple (@res)
    {
	my($cid,$reaction) = @$tuple;
	$to_reactions{$cid}->{$reaction} = 1;
    }
    @res    = $kb->GetAll('Complex IsTriggeredBy',
			  $complex_constraint,
			  $complexes,
			  'Complex(id) IsTriggeredBy(to-link) IsTriggeredBy(optional)');

    foreach my $tuple (@res)
    {
	my($cid,$role,$optional) = @$tuple;
	$to_roles{$cid}->{$role} = $optional;
    }
    foreach my $cid (@$complexes)
    {
	my $complex_name      = $to_name{$cid} || '';
	my $complex_roles     = defined($to_roles{$cid}) ?
	                        [map { [$_,$to_roles{$cid}->{$_}] } sort keys(%{$to_roles{$cid}})] : [];
	my $complex_reactions = $to_reactions{$cid} ? [sort keys(%{$to_reactions{$cid}})] : [];
	$return->{$cid} = { complex_name      => $complex_name,
			    complex_roles     => $complex_roles,
			    complex_reactions => $complex_reactions
			  };
    }
    return($return);
    #END complexes_to_complex_data
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to complexes_to_complex_data:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'complexes_to_complex_data');
    }
    return($return);
}




=head2 genomes_to_genome_data

  $return = $obj->genomes_to_genome_data($genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a genome_data
genomes is a reference to a list where each element is a genome
genome is a string
genome_data is a reference to a hash where the following keys are defined:
	complete has a value which is an int
	contigs has a value which is an int
	dna_size has a value which is an int
	gc_content has a value which is a float
	genetic_code has a value which is an int
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	taxonomy has a value which is a string
	genome_md5 has a value which is a string

</pre>

=end html

=begin text

$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a genome_data
genomes is a reference to a list where each element is a genome
genome is a string
genome_data is a reference to a hash where the following keys are defined:
	complete has a value which is an int
	contigs has a value which is an int
	dna_size has a value which is an int
	gc_content has a value which is a float
	genetic_code has a value which is an int
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	taxonomy has a value which is a string
	genome_md5 has a value which is a string


=end text



=item Description



=back

=cut

sub genomes_to_genome_data
{
    my $self = shift;
    my($genomes) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomes_to_genome_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_genome_data');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN genomes_to_genome_data
    $return = {};
    if (@$genomes < 1)  { return $return }
    my $kb = $self->{db};
    my $n = @$genomes;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $genome_constraint       = "Genome(id) IN $targets";
    my @res = $kb->GetAll('Genome',
			  $genome_constraint,
			  $genomes,
			  'Genome(id) Genome(complete) Genome(contigs) Genome(dna_size)
                           Genome(gc_content) Genome(genetic_code) Genome(pegs) Genome(rnas)
                           Genome(scientific_name) Genome(md5)'
			  );

    foreach my $tuple (@res)
    {
	my($id,$complete,$contigs,$dna_size,$gc_content,$genetic_code,
	   $pegs,$rnas,$scientific_name,$genome_md5) = @$tuple;
	$return->{$id} = { complete 	   => $complete,
			   contigs  	   => $contigs,
			   dna_size 	   => $dna_size,
			   gc_content 	   => $gc_content,
			   genetic_code    => $genetic_code,
			   pegs 	   => $pegs,
			   rnas		   => $rnas,
			   scientific_name => $scientific_name,
			   genome_md5 	   => $genome_md5
			 };

    }

    my $taxH = &genomes_to_taxonomies($self,$genomes);
    foreach my $genome (keys(%$taxH))
    {
	if (my $tax = $taxH->{$genome})
	{
	    $return->{$genome}->{taxonomy} = join("; ",@$tax);
	}
    }
    #END genomes_to_genome_data
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomes_to_genome_data:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomes_to_genome_data');
    }
    return($return);
}




=head2 fids_to_regulon_data

  $return = $obj->fids_to_regulon_data($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a regulons_data
fids is a reference to a list where each element is a fid
fid is a string
regulons_data is a reference to a list where each element is a regulon_data
regulon_data is a reference to a hash where the following keys are defined:
	regulon_id has a value which is a regulon
	regulon_set has a value which is a fids
	tfs has a value which is a fids
regulon is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a regulons_data
fids is a reference to a list where each element is a fid
fid is a string
regulons_data is a reference to a list where each element is a regulon_data
regulon_data is a reference to a hash where the following keys are defined:
	regulon_id has a value which is a regulon
	regulon_set has a value which is a fids
	tfs has a value which is a fids
regulon is a string


=end text



=item Description



=back

=cut

sub fids_to_regulon_data
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_regulon_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_regulon_data');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_regulon_data
    $return = {};
    if (@$fids < 1)  { return $return }
    my $kb = $self->{db};
    my $n = @$fids;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $fid_constraint       = "IsRegulatedIn(from-link) IN $targets";
    my @res = $kb->GetAll('IsRegulatedIn',
			  $fid_constraint,
			  $fids,
			  'IsRegulatedIn(from-link) IsRegulatedIn(to-link)'
			  );
    my %to_reg;
    my %regulons;
    foreach my $tuple (@res)
    {
	my($fid,$regulon) = @$tuple;
	$to_reg{$fid}->{$regulon} = 1;
	$regulons{$regulon} = {};
    }
    my @sets = keys(%regulons);
    if (@sets == 0) { return $return }

    $n       = @sets;
    $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $reg_constraint       = "IsRegulatedSetOf(from-link) IN $targets";
    @res = $kb->GetAll('IsRegulatedSetOf',
		       $reg_constraint,
		       \@sets,,
		       'IsRegulatedSetOf(from-link) IsRegulatedSetOf(to-link)'
		       );

    foreach my $tuple (@res)
    {
	my($regulon,$fid) = @$tuple;
	$regulons{$regulon}->{$fid} = 1;
    }
    my %controls;
    $reg_constraint       = "IsControlledUsing(from-link) IN $targets";
    @res = $kb->GetAll('IsControlledUsing',
		       $reg_constraint,
		       \@sets,
		       'IsControlledUsing(from-link) IsControlledUsing(to-link)'
		       );

    foreach my $tuple (@res)
    {
	my($regulon,$fid) = @$tuple;
	$controls{$regulon}->{$fid} = 1;
    }

    foreach my $fid (keys(%to_reg))
    {
	my $regulons_data = [];
	my $regH = $to_reg{$fid};
	foreach my $reg_in (keys(%$regH))
	{
	    my @mem = keys(%{$regulons{$reg_in}});
	    my @tfs = keys(%{$controls{$reg_in}});
	    push(@$regulons_data,{ regulon_set => \@mem,
				   regulon_id  => $reg_in,
				   tfs         => \@tfs });
	}
	$return->{$fid} = $regulons_data;
    }
    #END fids_to_regulon_data
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_regulon_data:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_regulon_data');
    }
    return($return);
}




=head2 regulons_to_fids

  $return = $obj->regulons_to_fids($regulons)

=over 4

=item Parameter and return types

=begin html

<pre>
$regulons is a regulons
$return is a reference to a hash where the key is a regulon and the value is a fids
regulons is a reference to a list where each element is a regulon
regulon is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$regulons is a regulons
$return is a reference to a hash where the key is a regulon and the value is a fids
regulons is a reference to a list where each element is a regulon
regulon is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description



=back

=cut

sub regulons_to_fids
{
    my $self = shift;
    my($regulons) = @_;

    my @_bad_arguments;
    (ref($regulons) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"regulons\" (value was \"$regulons\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to regulons_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'regulons_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN regulons_to_fids
    $return = {};
    if (@$regulons < 1) { return $return }

    my $kb = $self->{db};
    my $n = @$regulons;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $regulon_constraint = "IsRegulatedSetOf(from_link) IN $targets";

    my @res = $kb->GetAll('IsRegulatedSetOf',
			  $regulon_constraint,
			  $regulons,
			  'IsRegulatedSetOf(from_link) IsRegulatedSetOf(to_link)');

    foreach my $tuple (@res)
    {
	my($regulon,$fid) = @$tuple;
	push(@{$return->{$regulon}},$fid);
    }
    #END regulons_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to regulons_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'regulons_to_fids');
    }
    return($return);
}




=head2 fids_to_feature_data

  $return = $obj->fids_to_feature_data($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a feature_data
fids is a reference to a list where each element is a fid
fid is a string
feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a fid
	genome_name has a value which is a string
	feature_function has a value which is a string
	feature_length has a value which is an int
	feature_publications has a value which is a pubrefs
	feature_location has a value which is a location
pubrefs is a reference to a list where each element is a pubref
pubref is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a feature_data
fids is a reference to a list where each element is a fid
fid is a string
feature_data is a reference to a hash where the following keys are defined:
	feature_id has a value which is a fid
	genome_name has a value which is a string
	feature_function has a value which is a string
	feature_length has a value which is an int
	feature_publications has a value which is a pubrefs
	feature_location has a value which is a location
pubrefs is a reference to a list where each element is a pubref
pubref is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int


=end text



=item Description



=back

=cut

sub fids_to_feature_data
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_feature_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_feature_data');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_feature_data
    $return = {};
    if (@$fids < 1)  { return $return }
    my $kb = $self->{db};
    my $n = @$fids;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $fid_constraint       = "Feature(id) IN $targets";
    my $produces_constraint =  "Produces(from-link) IN $targets";
    my $loc_constraint       = "IsLocatedIn(from-link) IN $targets";
    my %genome;
    my %function;
    my %len;
    my %publications;
    my %location;
    my @locs = $kb->GetAll('IsLocatedIn',
			  $loc_constraint,
			  $fids,
			  'IsLocatedIn(from-link) IsLocatedIn(to-link) IsLocatedIn(begin) IsLocatedIn(dir) IsLocatedIn(len) IsLocatedIn(ordinal)'
			  );
    foreach my $tuple (sort { ($a->[0] cmp $b->[0]) or ($a->[5] <=> $b->[5]) } @locs)
    {
	my($fid,$contig,$begin,$dir,$len) = @$tuple;
	push(@{$location{$fid}},[$contig,$begin,$dir,$len]);
    }

    my @res = $kb->GetAll('Feature IsOwnedBy Genome',
			  $fid_constraint,
			  $fids,
			  'Feature(id) Genome(scientific_name) Feature(function) Feature(sequence_length)'
			  );

    foreach my $tuple (@res)
    {
	my($fid,$genome_name,$function,$length) = @$tuple;
	$genome{$fid}      = $genome_name;
	$function{$fid}    = $function;
	$len{$fid}         = $length;
    }

    @res = $kb->GetAll('Feature Produces ProteinSequence IsATopicOf Publication',
			  $produces_constraint,
			  $fids,
			  'Feature(id) IsATopicOf(to_link) Publication(link) Publication(title)'
			  );
    foreach my $tuple (@res)
    {
	my($fid,$pubid,$link,$title) = @$tuple;
	push(@{$publications{$fid}},[$pubid,$link,$title]);
    }
    foreach my $fid (@$fids)
    {
	my $function = $function{$fid}     || '';
	my $pubrefs  = $publications{$fid} || [];
	my $loc      = $location{$fid} || [];
	$return->{$fid} = { feature_id 		 => $fid,
			    genome_name 	 => $genome{$fid},
			    feature_function 	 => $function,
			    feature_length 	 => $len{$fid},
			    feature_publications => $pubrefs,
			    feature_location     => $loc
			   };
    }
    return($return);
    #END fids_to_feature_data
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_feature_data:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_feature_data');
    }
    return($return);
}




=head2 equiv_sequence_assertions

  $return = $obj->equiv_sequence_assertions($proteins)

=over 4

=item Parameter and return types

=begin html

<pre>
$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a function_assertions
proteins is a reference to a list where each element is a protein
protein is a string
function_assertions is a reference to a list where each element is a function_assertion
function_assertion is a reference to a list containing 3 items:
	0: an id
	1: a function
	2: a source
id is a string
function is a string
source is a string

</pre>

=end html

=begin text

$proteins is a proteins
$return is a reference to a hash where the key is a protein and the value is a function_assertions
proteins is a reference to a list where each element is a protein
protein is a string
function_assertions is a reference to a list where each element is a function_assertion
function_assertion is a reference to a list containing 3 items:
	0: an id
	1: a function
	2: a source
id is a string
function is a string
source is a string


=end text



=item Description

Different groups have made assertions of function for numerous protein sequences.
The equiv_sequence_assertions allows the user to gather function assertions from
all of the sources.  Each assertion includes a field indicating whether the person making
the assertion viewed themself as an "expert".  The routine gathers assertions for all
proteins having identical protein sequence.

=back

=cut

sub equiv_sequence_assertions
{
    my $self = shift;
    my($proteins) = @_;

    my @_bad_arguments;
    (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"proteins\" (value was \"$proteins\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to equiv_sequence_assertions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'equiv_sequence_assertions');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN equiv_sequence_assertions
    $return = {};
    if (@$proteins < 1) { return $return }
    my $kb = $self->{db};

    my $n = @$proteins;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $protein_constraint1 = "HasAssertedFunctionFrom(from_link) IN $targets";
    my $protein_constraint2 = "IsProteinFor(from_link) IN $targets";
    my @res = $kb->GetAll('IsProteinFor Feature IsOwnedBy Genome WasSubmittedBy',
			  $protein_constraint2,
			  $proteins,
			  'IsProteinFor(from_link) Feature(source_id) Feature(function) WasSubmittedBy(to_link)');

    foreach my $tuple (@res)
    {
	my($md5,$id,$function,$source) = @$tuple;
	push(@{$return->{$md5}},[$id,$function,$source]);
    }

    @res = $kb->GetAll('HasAssertedFunctionFrom',
			  $protein_constraint1,
			  $proteins,
			  'HasAssertedFunctionFrom(from_link) HasAssertedFunctionFrom(external_id) HasAssertedFunctionFrom(function) HasAssertedFunctionFrom(to_link)');

    foreach my $tuple (@res)
    {
	my($md5,$id,$function,$source) = @$tuple;
	push(@{$return->{$md5}},[$id,$function,$source]);
    }

    #END equiv_sequence_assertions
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to equiv_sequence_assertions:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'equiv_sequence_assertions');
    }
    return($return);
}




=head2 fids_to_atomic_regulons

  $return = $obj->fids_to_atomic_regulons($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is an atomic_regulon_size_pairs
fids is a reference to a list where each element is a fid
fid is a string
atomic_regulon_size_pairs is a reference to a list where each element is an atomic_regulon_size_pair
atomic_regulon_size_pair is a reference to a list containing 2 items:
	0: an atomic_regulon
	1: an atomic_regulon_size
atomic_regulon is a string
atomic_regulon_size is an int

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is an atomic_regulon_size_pairs
fids is a reference to a list where each element is a fid
fid is a string
atomic_regulon_size_pairs is a reference to a list where each element is an atomic_regulon_size_pair
atomic_regulon_size_pair is a reference to a list containing 2 items:
	0: an atomic_regulon
	1: an atomic_regulon_size
atomic_regulon is a string
atomic_regulon_size is an int


=end text



=item Description

The fids_to_atomic_regulons allows one to map fids into regulons that contain the fids.
Normally a fid will be in at most one regulon, but we support multiple regulons.

=back

=cut

sub fids_to_atomic_regulons
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_atomic_regulons:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_atomic_regulons');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_atomic_regulons
    $return = {};
    my $kb = $self->{db};
    for my $fid (@$fids)
    {
	my @res = $kb->GetAll('IsFormedInto AtomicRegulon IsFormedOf2',
			       'IsFormedInto(from_link) = ?',
			       [$fid],
			       'AtomicRegulon(id) IsFormedOf2(to_link)');

        if (@res != 0) {
		my %counts;
		$counts{$_->[0]}++ foreach @res;
		while (my($ar,$n) = each %counts) { push(@{$return->{$fid}},[$ar,$n]) }
        }
    }
    #END fids_to_atomic_regulons
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_atomic_regulons:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_atomic_regulons');
    }
    return($return);
}




=head2 atomic_regulons_to_fids

  $return = $obj->atomic_regulons_to_fids($atomic_regulons)

=over 4

=item Parameter and return types

=begin html

<pre>
$atomic_regulons is an atomic_regulons
$return is a reference to a hash where the key is an atomic_regulon and the value is a fids
atomic_regulons is a reference to a list where each element is an atomic_regulon
atomic_regulon is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$atomic_regulons is an atomic_regulons
$return is a reference to a hash where the key is an atomic_regulon and the value is a fids
atomic_regulons is a reference to a list where each element is an atomic_regulon
atomic_regulon is a string
fids is a reference to a list where each element is a fid
fid is a string


=end text



=item Description

The atomic_regulons_to_fids routine allows the user to access the set of fids that make up a regulon.
Regulons may arise from several sources; hence, fids can be in multiple regulons.

=back

=cut

sub atomic_regulons_to_fids
{
    my $self = shift;
    my($atomic_regulons) = @_;

    my @_bad_arguments;
    (ref($atomic_regulons) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"atomic_regulons\" (value was \"$atomic_regulons\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to atomic_regulons_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'atomic_regulons_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN atomic_regulons_to_fids
    $return = {};
    if (@$atomic_regulons < 1) { return $return }
    my $kb = $self->{db};
    my $n = @$atomic_regulons;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $ar_constraint = "IsFormedOf(from-link) IN $targets";

    my @res = $kb->GetAll('IsFormedOf',
			  $ar_constraint,
			  $atomic_regulons,
			  'IsFormedOf(from_link) IsFormedOf(to_link)');

    foreach my $tuple (@res)
    {
	my($ar,$fid) = @$tuple;
	push(@{$return->{$ar}},$fid);
    }

    #END atomic_regulons_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to atomic_regulons_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'atomic_regulons_to_fids');
    }
    return($return);
}




=head2 fids_to_protein_sequences

  $return = $obj->fids_to_protein_sequences($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a protein_sequence
fids is a reference to a list where each element is a fid
fid is a string
protein_sequence is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a protein_sequence
fids is a reference to a list where each element is a fid
fid is a string
protein_sequence is a string


=end text



=item Description

fids_to_protein_sequences allows the user to look up the amino acid sequences
corresponding to each of a set of fids.  You can also get the sequence from proteins (i.e., md5 values).
This routine saves you having to look up the md5 sequence and then accessing
the protein string in a separate call.

=back

=cut

sub fids_to_protein_sequences
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_protein_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_protein_sequences');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_protein_sequences
    $return = {};
    if (@$fids < 1) { return $return }

    my $kb = $self->{db};
    my $n = @$fids;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $fid_constraint = "Produces(from_link) IN $targets";

    my @res = $kb->GetAll('Produces ProteinSequence',
			  $fid_constraint,
			  $fids,
			  'Produces(from_link) ProteinSequence(sequence)');

    foreach my $tuple (@res)
    {
	my($fid,$seq) = @$tuple;
	$return->{$fid} = $seq;
    }
    #END fids_to_protein_sequences
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_protein_sequences:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_protein_sequences');
    }
    return($return);
}




=head2 fids_to_proteins

  $return = $obj->fids_to_proteins($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a md5
fids is a reference to a list where each element is a fid
fid is a string
md5 is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a md5
fids is a reference to a list where each element is a fid
fid is a string
md5 is a string


=end text



=item Description



=back

=cut

sub fids_to_proteins
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_proteins');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_proteins
    $return = {};
    if (@$fids < 1) { return $return }

    my $kb = $self->{db};
    my $n = @$fids;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $fid_constraint = "Produces(from_link) IN $targets";

    my @res = $kb->GetAll('Produces ProteinSequence',
			  $fid_constraint,
			  $fids,
			  'Produces(from_link) Produces(to_link)');

    foreach my $tuple (@res)
    {
	my($fid,$md5) = @$tuple;
	$return->{$fid} = $md5;
    }
    #END fids_to_proteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_proteins');
    }
    return($return);
}




=head2 fids_to_dna_sequences

  $return = $obj->fids_to_dna_sequences($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a dna_sequence
fids is a reference to a list where each element is a fid
fid is a string
dna_sequence is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a dna_sequence
fids is a reference to a list where each element is a fid
fid is a string
dna_sequence is a string


=end text



=item Description

fids_to_dna_sequences allows the user to look up the DNA sequences
corresponding to each of a set of fids.

=back

=cut

sub fids_to_dna_sequences
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_dna_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_dna_sequences');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_dna_sequences
    $return = {};
    my $kb = $self->{db};
    for my $fid (@$fids) {
        my @locs = $kb->GetLocations($fid);
        my @dna;
        for my $loc (@locs) {
            push @dna, $kb->ComputeDNA($loc->Contig, $loc->Begin, $loc->Dir, $loc->Length);
        }
        $return->{$fid} = join("", @dna);
    }
    #END fids_to_dna_sequences
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_dna_sequences:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_dna_sequences');
    }
    return($return);
}




=head2 roles_to_fids

  $return = $obj->roles_to_fids($roles, $genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$roles is a roles
$genomes is a genomes
$return is a reference to a hash where the key is a role and the value is a fid
roles is a reference to a list where each element is a role
role is a string
genomes is a reference to a list where each element is a genome
genome is a string
fid is a string

</pre>

=end html

=begin text

$roles is a roles
$genomes is a genomes
$return is a reference to a hash where the key is a role and the value is a fid
roles is a reference to a list where each element is a role
role is a string
genomes is a reference to a list where each element is a genome
genome is a string
fid is a string


=end text



=item Description

A "function" is a set of "roles" (often called "functional roles");

                F1 / F2  (where F1 and F2 are roles)  is a function that implements
                          two functional roles in different domains of the protein.
                F1 @ F2 implements multiple roles through broad specificity
                F1; F2  is thought to implement F1 or f2 (uncertainty)

            You often wish to find the fids in one or more genomes that
            implement specific functional roles.  To do this, you can use
            roles_to_fids.

=back

=cut

sub roles_to_fids
{
    my $self = shift;
    my($roles, $genomes) = @_;

    my @_bad_arguments;
    (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"roles\" (value was \"$roles\")");
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to roles_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_fids');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN roles_to_fids
    my $kb = $self->{db};
    $return = {};
    if ((! $roles) || (@$roles == 0)) { return $return }
    my @parms;

    my $n = @$roles;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $role_constraint = "IsFunctionalIn(from_link) IN $targets";
    push @parms, @$roles;
    my $genome_constraint = "";
    if (@$genomes > 0)
    {
	$n = @$genomes;
	$targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
	$genome_constraint = "AND IsOwnedBy(to_link) IN $targets";
	push @parms, @$genomes;
    }
    my @resultRows = $kb->GetAll("IsFunctionalIn Feature IsOwnedBy",
				  "$role_constraint $genome_constraint",
				  \@parms,
				  'IsFunctionalIn(from_link) IsFunctionalIn(to_link)');
    foreach $_ (@resultRows)
    {
	my($role,$fid) = @$_;
	push(@{$return->{$role}},$fid);
    }
    #END roles_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to roles_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_fids');
    }
    return($return);
}




=head2 reactions_to_complexes

  $return = $obj->reactions_to_complexes($reactions)

=over 4

=item Parameter and return types

=begin html

<pre>
$reactions is a reactions
$return is a reference to a hash where the key is a reaction and the value is a complexes_with_flags
reactions is a reference to a list where each element is a reaction
reaction is a string
complexes_with_flags is a reference to a list where each element is a complex_with_flag
complex_with_flag is a reference to a list containing 2 items:
	0: a complex
	1: an optional
complex is a string
optional is a string

</pre>

=end html

=begin text

$reactions is a reactions
$return is a reference to a hash where the key is a reaction and the value is a complexes_with_flags
reactions is a reference to a list where each element is a reaction
reaction is a string
complexes_with_flags is a reference to a list where each element is a complex_with_flag
complex_with_flag is a reference to a list containing 2 items:
	0: a complex
	1: an optional
complex is a string
optional is a string


=end text



=item Description

Reactions are thought of as being either spontaneous or implemented by
one or more Complexes.  Complexes connect to Roles.  Hence, the connection of fids
or roles to reactions goes through Complexes.

=back

=cut

sub reactions_to_complexes
{
    my $self = shift;
    my($reactions) = @_;

    my @_bad_arguments;
    (ref($reactions) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"reactions\" (value was \"$reactions\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to reactions_to_complexes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reactions_to_complexes');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN reactions_to_complexes
    my $kb = $self->{db};
    $return = {};

    for my $reaction (@$reactions)
    {
	my @comp = $kb->GetFlat('IsUsedAs ReactionRule IsStepOf',
				'IsUsedAs(from_link) = ?',
				[$reaction],
				'IsStepOf(to_link)');
	if (@comp)
	{
	    my %tmp = map { $_ => 1 } @comp;
	    my $comp = [sort keys(%tmp)];
	    $return->{$reaction} = $comp;
	}
    }

    #END reactions_to_complexes
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to reactions_to_complexes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reactions_to_complexes');
    }
    return($return);
}




=head2 reaction_strings

  $return = $obj->reaction_strings($reactions, $name_parameter)

=over 4

=item Parameter and return types

=begin html

<pre>
$reactions is a reactions
$name_parameter is a name_parameter
$return is a reference to a hash where the key is a reaction and the value is a string
reactions is a reference to a list where each element is a reaction
reaction is a string
name_parameter is a string

</pre>

=end html

=begin text

$reactions is a reactions
$name_parameter is a name_parameter
$return is a reference to a hash where the key is a reaction and the value is a string
reactions is a reference to a list where each element is a reaction
reaction is a string
name_parameter is a string


=end text



=item Description

Reaction_strings are text strings that represent (albeit crudely)
the details of Reactions.

=back

=cut

sub reaction_strings
{
    my $self = shift;
    my($reactions, $name_parameter) = @_;

    my @_bad_arguments;
    (ref($reactions) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"reactions\" (value was \"$reactions\")");
    (!ref($name_parameter)) or push(@_bad_arguments, "Invalid type for argument \"name_parameter\" (value was \"$name_parameter\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to reaction_strings:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reaction_strings');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN reaction_strings
    $return = {};
    my $kb = $self->{db};
    for my $reaction (@$reactions)
    {
	    my @resultRows = $kb->GetAll("Compound ParticipatesAs Reagent IsInvolvedIn Reaction","Reaction(id) = ?", [$reaction],[qw(
	    	Reagent(id)
	    	Compound(label)
	        Reagent(cofactor)
	        Reagent(compartment_index)
	        Reagent(stoichiometry)
	        Reagent(transport_coefficient)
	    )]);
		#Assembling data on reaction reagents
		my $reactantHash;
		foreach my $row (@resultRows) {
			if (!defined($reactantHash->{$row->[0]})) {
				$reactantHash->{$row->[0]} = {
					coef => 0,
					name => $row->[1],
					comp => 0
				};
			}
			$reactantHash->{$row->[0]}->{coef} += $row->[4];
			if ($row->[5] != 0) {
				$reactantHash->{$row->[0].".".$row->[3]} = {
					coef => -1*$row->[5],
					name => $row->[1],
					comp => $row->[3]
				};
				$reactantHash->{$row->[0]}->{coef} += $row->[5];
			}
		}
		#Identifying reactants and products
		my $reactants = [];
		my $products = [];
		foreach my $reactant (keys(%{$reactantHash})) {
			if ($reactantHash->{$reactant}->{coef} < 0) {
				push(@{$reactants},$reactant);
			} elsif ($reactantHash->{$reactant}->{coef} > 0) {
				push(@{$products},$reactant);
			}
		}
		@{$reactants} = sort(@{$reactants});
		@{$products} = sort(@{$products});
		#Building the reaction equation string
    	my $equationString = "";
    	foreach my $reactant (@$reactants) {
    		$reactantHash->{$reactant}->{coef} = $reactantHash->{$reactant}->{coef}*(-1);
    		if (length($equationString) > 0) {
    			$equationString .= " + ";
    		}
    		if ($reactantHash->{$reactant}->{coef} != 1) {
    			$equationString .= "(".$reactantHash->{$reactant}->{coef}.") ";
    		}
    		$equationString .= $reactantHash->{$reactant}->{name};
    		if ($reactantHash->{$reactant}->{comp} != 0) {
    			$equationString .= "[".$reactantHash->{$reactant}->{comp}."]";
    		}
    	}
    	$equationString .= " <=> ";
    	my $productString = "";
    	foreach my $reactant (@$products) {
    		if (length($productString) > 0) {
    			$productString .= " + ";
    		}
    		if ($reactantHash->{$reactant}->{coef} != 1) {
    			$productString .= "(".$reactantHash->{$reactant}->{coef}.") ";
    		}
    		$productString .= $reactantHash->{$reactant}->{name};
    		if ($reactantHash->{$reactant}->{comp} != 0) {
    			$productString .= "[".$reactantHash->{$reactant}->{comp}."]";
    		}
    	}
    	$equationString .= $productString;
    	$return->{$reaction} = $equationString;
    }
    #END reaction_strings
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to reaction_strings:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reaction_strings');
    }
    return($return);
}




=head2 roles_to_complexes

  $return = $obj->roles_to_complexes($roles)

=over 4

=item Parameter and return types

=begin html

<pre>
$roles is a roles
$return is a reference to a hash where the key is a role and the value is a complexes
roles is a reference to a list where each element is a role
role is a string
complexes is a reference to a list where each element is a complex
complex is a string

</pre>

=end html

=begin text

$roles is a roles
$return is a reference to a hash where the key is a role and the value is a complexes
roles is a reference to a list where each element is a role
role is a string
complexes is a reference to a list where each element is a complex
complex is a string


=end text



=item Description

roles_to_complexes allows a user to connect Roles to Complexes,
from there, the connection exists to Reactions (although in the
actual ER-model model, the connection from Complex to Reaction goes through
ReactionComplex).  Since Roles also connect to fids, the connection between
fids and Reactions is induced.

The "name_parameter" can be 0, 1 or 'only'. If 1, then the compound name will 
be included with the ID in the output. If only, the compound name will be included 
instead of the ID. If 0, only the ID will be included. The default is 0.

=back

=cut

sub roles_to_complexes
{
    my $self = shift;
    my($roles) = @_;

    my @_bad_arguments;
    (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"roles\" (value was \"$roles\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to roles_to_complexes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_complexes');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN roles_to_complexes
    my $kb = $self->{db};
    $return = {};
    if ((! $roles) || (@$roles == 0)) { return $return }

    my $n = @$roles;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $role_constraint = "Triggers(from_link) IN $targets";

    my @res = $kb->GetAll('Triggers Complex',
			  $role_constraint,
			  $roles,
			  'Triggers(from-link) Triggers(to-link) Triggers(optional)');

    foreach my $tuple (@res)
    {
	my($role,$complex,$optional) = @$tuple;
	push(@{$return->{$role}},[$complex,$optional]);
    }

    #END roles_to_complexes
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to roles_to_complexes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'roles_to_complexes');
    }
    return($return);
}




=head2 complexes_to_roles

  $return = $obj->complexes_to_roles($complexes)

=over 4

=item Parameter and return types

=begin html

<pre>
$complexes is a complexes
$return is a reference to a hash where the key is a complexes and the value is a roles
complexes is a reference to a list where each element is a complex
complex is a string
roles is a reference to a list where each element is a role
role is a string

</pre>

=end html

=begin text

$complexes is a complexes
$return is a reference to a hash where the key is a complexes and the value is a roles
complexes is a reference to a list where each element is a complex
complex is a string
roles is a reference to a list where each element is a role
role is a string


=end text



=item Description



=back

=cut

sub complexes_to_roles
{
    my $self = shift;
    my($complexes) = @_;

    my @_bad_arguments;
    (ref($complexes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"complexes\" (value was \"$complexes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to complexes_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'complexes_to_roles');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN complexes_to_roles
    my $kb = $self->{db};
    $return = {};
    if (@$complexes < 1) { return $return }

    my $n = @$complexes;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $complex_constraint = "IsTriggeredBy(from_link) IN $targets";

    my @res = $kb->GetAll('IsTriggeredBy',
			  $complex_constraint,
			  $complexes,
			  'IsTriggeredBy(from_link) IsTriggeredBy(to_link)');

    foreach my $tuple (@res)
    {
	my($complex,$role) = @$tuple;
	push(@{$return->{$complex}},$role);
    }

    #END complexes_to_roles
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to complexes_to_roles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'complexes_to_roles');
    }
    return($return);
}




=head2 fids_to_subsystem_data

  $return = $obj->fids_to_subsystem_data($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a ss_var_role_tuples
fids is a reference to a list where each element is a fid
fid is a string
ss_var_role_tuples is a reference to a list where each element is a ss_var_role_tuple
ss_var_role_tuple is a reference to a list containing 3 items:
	0: a subsystem
	1: a variant
	2: a role
subsystem is a string
variant is a string
role is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a ss_var_role_tuples
fids is a reference to a list where each element is a fid
fid is a string
ss_var_role_tuples is a reference to a list where each element is a ss_var_role_tuple
ss_var_role_tuple is a reference to a list containing 3 items:
	0: a subsystem
	1: a variant
	2: a role
subsystem is a string
variant is a string
role is a string


=end text



=item Description



=back

=cut

sub fids_to_subsystem_data
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_subsystem_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_subsystem_data');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_subsystem_data
    my $kb = $self->{db};
    $return = {};
    for my $fid (@$fids) {
        my @subTuples = $kb->GetAll("IsContainedIn SSCell HasRole AND SSCell IsRoleFor Implements Variant IsDescribedBy",
                                    "IsContainedIn(from_link) = ?", [$fid],
                                    'IsDescribedBy(to_link) Variant(code) HasRole(to_link)');
        $return->{$fid} = \@subTuples if @subTuples;
    }
    #END fids_to_subsystem_data
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_subsystem_data:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_subsystem_data');
    }
    return($return);
}




=head2 representative

  $return = $obj->representative($genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a genome
genomes is a reference to a list where each element is a genome
genome is a string

</pre>

=end html

=begin text

$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a genome
genomes is a reference to a list where each element is a genome
genome is a string


=end text



=item Description



=back

=cut

sub representative
{
    my $self = shift;
    my($genomes) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to representative:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'representative');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN representative
    my $kb = $self->{db};
    $return = {};
    if (@$genomes < 1) {return $return }

    my $n = @$genomes;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $genome_constraint = "IsCollectedInto(from_link) IN $targets";

    my @res = $kb->GetAll('IsCollectedInto OTU IsCollectionOf',
			  "$genome_constraint AND IsCollectionOf(representative) = 1",
			  $genomes,
			  'IsCollectedInto(from_link) IsCollectionOf(to_link)');

    foreach my $tuple (@res)
    {
	my($genome,$rep) = @$tuple;
	$return->{$genome} = $rep;
    }

    #END representative
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to representative:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'representative');
    }
    return($return);
}




=head2 otu_members

  $return = $obj->otu_members($genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a reference to a hash where the key is a genome and the value is a genome_name
genomes is a reference to a list where each element is a genome
genome is a string
genome_name is a string

</pre>

=end html

=begin text

$genomes is a genomes
$return is a reference to a hash where the key is a genome and the value is a reference to a hash where the key is a genome and the value is a genome_name
genomes is a reference to a list where each element is a genome
genome is a string
genome_name is a string


=end text



=item Description



=back

=cut

sub otu_members
{
    my $self = shift;
    my($genomes) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to otu_members:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'otu_members');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN otu_members
    my $kb = $self->{db};
    $return = {};
    if (@$genomes < 1) {return $return }

    my $n = @$genomes;
    my $targets = "(" . ('?,' x $n); chop $targets; $targets .= ')';
    my $genome_constraint = "IsCollectedInto(from_link) IN $targets";

    my @res = $kb->GetAll('IsCollectedInto OTU IsCollectionOf',
			  $genome_constraint,
			  $genomes,
			  'IsCollectedInto(from_link) IsCollectionOf(to_link)');

    foreach my $tuple (@res)
    {
	my($genome,$rep) = @$tuple;
	push(@{$return->{$genome}},$rep);
    }

    #END otu_members
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to otu_members:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'otu_members');
    }
    return($return);
}




=head2 fids_to_genomes

  $return = $obj->fids_to_genomes($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a genome
fids is a reference to a list where each element is a fid
fid is a string
genome is a string

</pre>

=end html

=begin text

$fids is a fids
$return is a reference to a hash where the key is a fid and the value is a genome
fids is a reference to a list where each element is a fid
fid is a string
genome is a string


=end text



=item Description



=back

=cut

sub fids_to_genomes
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_genomes');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN fids_to_genomes
    $return = {};
    foreach my $fid (@$fids)
    {
	if ($fid =~ /^(kb\|g\.\d+)/)
	{
	    $return->{$fid} = $1;
	}
    }
    #END fids_to_genomes
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_genomes');
    }
    return($return);
}




=head2 text_search

  $return = $obj->text_search($input, $start, $count, $entities)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a string
$start is an int
$count is an int
$entities is a reference to a list where each element is a string
$return is a reference to a hash where the key is an entity_name and the value is a reference to a list where each element is a search_hit
entity_name is a string
search_hit is a reference to a list containing 2 items:
	0: a weight
	1: a reference to a hash where the key is a field_name and the value is a string
weight is an int
field_name is a string

</pre>

=end html

=begin text

$input is a string
$start is an int
$count is an int
$entities is a reference to a list where each element is a string
$return is a reference to a hash where the key is an entity_name and the value is a reference to a list where each element is a search_hit
entity_name is a string
search_hit is a reference to a list containing 2 items:
	0: a weight
	1: a reference to a hash where the key is a field_name and the value is a string
weight is an int
field_name is a string


=end text



=item Description

text_search performs a search against a full-text index maintained 
for the CDMI. The parameter "input" is the text string to be searched for.
The parameter "entities" defines the entities to be searched. If the list
is empty, all indexed entities will be searched. The "start" and "count"
parameters limit the results to "count" hits starting at "start".

=back

=cut

sub text_search
{
    my $self = shift;
    my($input, $start, $count, $entities) = @_;

    my @_bad_arguments;
    (!ref($input)) or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    (!ref($start)) or push(@_bad_arguments, "Invalid type for argument \"start\" (value was \"$start\")");
    (!ref($count)) or push(@_bad_arguments, "Invalid type for argument \"count\" (value was \"$count\")");
    (ref($entities) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"entities\" (value was \"$entities\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to text_search:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'text_search');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN text_search
    my $sphinx = Sphinx::Search->new;
    my $host = $ENV{KB_SPHINX_HOST} || "ash.mcs.anl.gov";
    my $port = $ENV{KB_SPHINX_PORT} || 7038;
    $sphinx->SetServer($host, $port);
    my @entities = @$entities;
    @entities = qw(Genome Feature Contig Subsystem Role) if @entities == 0;

    my @indexes = map { $_ . "_index" } @entities;

    $sphinx->SetLimits($start, $count);

    for my $idx (@indexes)
    {
	$sphinx->AddQuery($input, $idx);
    }

    my $ret = $sphinx->RunQueries();

    $return = {};

    for (my $i = 0; $i < @$ret; $i++)
    {
	my $idx_name = $indexes[$i];
	my $idx_dat = $ret->[$i];
	my $entity = $entities[$i];

	my $list = [];
	$return->{$entity} = $list;

	for my $ent (@{$idx_dat->{matches}})
	{
	    my $weight = delete $ent->{weight};
	    my $row = [$weight, $ent];
	    push(@$list, $row);
	}
    }


    #END text_search
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to text_search:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'text_search');
    }
    return($return);
}




=head2 corresponds

  $return = $obj->corresponds($fids, $genome)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$genome is a genome
$return is a reference to a hash where the key is a fid and the value is a correspondence
fids is a reference to a list where each element is a fid
fid is a string
genome is a string
correspondence is a reference to a hash where the following keys are defined:
	to has a value which is a fid
	iden has a value which is a float
	ncontext has a value which is an int
	b1 has a value which is an int
	e1 has a value which is an int
	ln1 has a value which is an int
	b2 has a value which is an int
	e2 has a value which is an int
	ln2 has a value which is an int
	score has a value which is an int

</pre>

=end html

=begin text

$fids is a fids
$genome is a genome
$return is a reference to a hash where the key is a fid and the value is a correspondence
fids is a reference to a list where each element is a fid
fid is a string
genome is a string
correspondence is a reference to a hash where the following keys are defined:
	to has a value which is a fid
	iden has a value which is a float
	ncontext has a value which is an int
	b1 has a value which is an int
	e1 has a value which is an int
	ln1 has a value which is an int
	b2 has a value which is an int
	e2 has a value which is an int
	ln2 has a value which is an int
	score has a value which is an int


=end text



=item Description



=back

=cut

sub corresponds
{
    my $self = shift;
    my($fids, $genome) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    (!ref($genome)) or push(@_bad_arguments, "Invalid type for argument \"genome\" (value was \"$genome\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to corresponds:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'corresponds');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN corresponds
    use Corresponds;
    $return = {};
    my $gH      = $self->genomes_to_fids([$genome],['peg','CDS']);
    my $fids_to = $gH->{$genome};
    my $loc2H   = $self->fids_to_locations($fids_to);
    my $seq2H   = $self->fids_to_protein_sequences($fids_to);
    my @seqs2   = map { my $loc2 = $loc2H->{$_}; 
			my $seq2 = $seq2H->{$_};
			($seq2 && $loc2) ? [$_,'',$seq2] : () } @$fids_to;
    my @locs2   = map { my $loc2 = $loc2H->{$_}; 
			my $seq2 = $seq2H->{$_};
			($seq2 && $loc2) ? [$_,$loc2] : () } @$fids_to;
    my %genomes_to_fids;
    foreach $_ (@$fids)
    {
	if ($_ =~ /^(kb\|g\.\d+)/)
	{
	    push(@{$genomes_to_fids{$1}},$_);
	}
    }
    foreach my $g (keys(%genomes_to_fids))
    {
	my $gH            = $self->genomes_to_fids([$g],['peg','CDS']);
	my $fids_from_all = $gH->{$g};
	my %fids_from     = map { $_ => 1 } @{$genomes_to_fids{$g}};

	my $loc1H     = $self->fids_to_locations($fids_from_all);
	my $seq1H     = $self->fids_to_protein_sequences($fids_from_all);
	my @seqs1     = map { my $loc1 = $loc1H->{$_}; 
			      my $seq1 = $seq1H->{$_};
			      ($seq1 && $loc1) ? [$_,'',$seq1] : () } @$fids_from_all;
	my @locs1     = map { my $loc1 = $loc1H->{$_}; 
			      my $seq1 = $seq1H->{$_};
			      ($seq1 && $loc1) ? [$_,$loc1] : () } @$fids_from_all;
	my($corr,$reps2,$reps1) = &Corresponds::correspondence_of_reps(\@seqs1,
								       \@locs1,
								       \@seqs2,
								       \@locs2,
								       5,
								       200);
	foreach my $x (@$corr)
	{
	    my($id1,$iden,$ncontext,$b1,$e1,$ln1,$b2,$e2,$ln2,$score,$to) = @$x;
	    if ($fids_from{$id1})
	    {
		$return->{$id1} = { to       => $to,
				    iden     => $iden,
				    ncontext => $ncontext,
				    b1       => $b1,
				    e1       => $e1,
				    ln1      => $ln1,
				    b2       => $b2,
				    e2       => $e2,
				    ln2      => $ln2,
				    score    => $score
				  };
	    }
	}

#	foreach my $group (@$reps2)    ### filling in all members in a locus
#	{
#	    if (@{$group->[1]} > 1)
#	    {
#		my $rep  = $group->[0]->[0];
#		my $same = $group->[1];
#		foreach my $x (@$same)
#		{
#		    $return->{$x->[0]} = $return->{$rep};
#		}
#	    }
#	}
    }
    #END corresponds
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to corresponds:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'corresponds');
    }
    return($return);
}




=head2 corresponds_from_sequences

  $return = $obj->corresponds_from_sequences($g1_sequences, $g1_locations, $g2_sequences, $g2_locations)

=over 4

=item Parameter and return types

=begin html

<pre>
$g1_sequences is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a protein_sequence
$g1_locations is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a location
$g2_sequences is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a protein_sequence
$g2_locations is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a location
$return is a reference to a hash where the key is a fid and the value is a correspondence
fid is a string
protein_sequence is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
correspondence is a reference to a hash where the following keys are defined:
	to has a value which is a fid
	iden has a value which is a float
	ncontext has a value which is an int
	b1 has a value which is an int
	e1 has a value which is an int
	ln1 has a value which is an int
	b2 has a value which is an int
	e2 has a value which is an int
	ln2 has a value which is an int
	score has a value which is an int

</pre>

=end html

=begin text

$g1_sequences is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a protein_sequence
$g1_locations is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a location
$g2_sequences is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a protein_sequence
$g2_locations is a reference to a list where each element is a reference to a list containing 2 items:
	0: a fid
	1: a location
$return is a reference to a hash where the key is a fid and the value is a correspondence
fid is a string
protein_sequence is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig
	1: a begin
	2: a strand
	3: a length
contig is a string
begin is an int
strand is a string
length is an int
correspondence is a reference to a hash where the following keys are defined:
	to has a value which is a fid
	iden has a value which is a float
	ncontext has a value which is an int
	b1 has a value which is an int
	e1 has a value which is an int
	ln1 has a value which is an int
	b2 has a value which is an int
	e2 has a value which is an int
	ln2 has a value which is an int
	score has a value which is an int


=end text



=item Description



=back

=cut

sub corresponds_from_sequences
{
    my $self = shift;
    my($g1_sequences, $g1_locations, $g2_sequences, $g2_locations) = @_;

    my @_bad_arguments;
    (ref($g1_sequences) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"g1_sequences\" (value was \"$g1_sequences\")");
    (ref($g1_locations) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"g1_locations\" (value was \"$g1_locations\")");
    (ref($g2_sequences) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"g2_sequences\" (value was \"$g2_sequences\")");
    (ref($g2_locations) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"g2_locations\" (value was \"$g2_locations\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to corresponds_from_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'corresponds_from_sequences');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN corresponds_from_sequences
    
    use Corresponds;
    $return = {};
    
    my($corr,$reps2,$reps1) = &Corresponds::correspondence_of_reps([map { [$_->[0], undef, $_->[1]] } @$g1_sequences],
								   $g1_locations,
								   [map { [$_->[0], undef, $_->[1]] } @$g2_sequences],
								   $g2_locations,
								   5,
								   200);
    foreach my $x (@$corr)
    {
	my($id1,$iden,$ncontext,$b1,$e1,$ln1,$b2,$e2,$ln2,$score,$to) = @$x;
	
	$return->{$id1} = { to       => $to,
				iden     => $iden,
				ncontext => $ncontext,
				b1       => $b1,
				e1       => $e1,
				ln1      => $ln1,
				b2       => $b2,
				e2       => $e2,
				ln2      => $ln2,
				score    => $score
				};
    }
    
    
    #END corresponds_from_sequences
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to corresponds_from_sequences:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'corresponds_from_sequences');
    }
    return($return);
}




=head2 close_genomes

  $return = $obj->close_genomes($genomes, $n)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$n is an int
$return is a reference to a hash where the key is a genome and the value is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome
	1: a float
genomes is a reference to a list where each element is a genome
genome is a string

</pre>

=end html

=begin text

$genomes is a genomes
$n is an int
$return is a reference to a hash where the key is a genome and the value is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome
	1: a float
genomes is a reference to a list where each element is a genome
genome is a string


=end text



=item Description

A close_genomes is used to get a set of relatively close genomes (for
each input genome, a set of close genomes is calculated, but the
result should be viewed as quite approximate.  It is quite slow,
using similarities for a universal protein as the basis for the 
assessments.  It produces estimates of degree of similarity for
the universal proteins it samples. 


Up to n genomes will be returned for each input genome.

=back

=cut

sub close_genomes
{
    my $self = shift;
    my($genomes, $n) = @_;

    my @_bad_arguments;
    (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"genomes\" (value was \"$genomes\")");
    (!ref($n)) or push(@_bad_arguments, "Invalid type for argument \"n\" (value was \"$n\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to close_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'close_genomes');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN close_genomes
    $return = {};
    use CloseGenomes;
    foreach my $g (@$genomes)
    {
	my $parms = {};
	my $contigs;
	if ($g =~ /^kb\|/)
	{
	    open(CONTIGS,"echo '$g' | genomes_to_contigs | contigs_to_sequences |");
	    $contigs = &gjoseqlib::read_fasta(\*CONTIGS);
	    close(CONTIGS);
	    $parms->{-source} = "KBase";
	    use Bio::KBase::CDMI::CDMIClient;
	    use Bio::KBase::Utilities::ScriptThing;
	    $parms->{-csObj} = Bio::KBase::CDMI::CDMIClient->new_for_script();
	}
	elsif (($g =~ /^\d+\.\d+/) && (! -d $g))
	{
	    open(CONTIGS,"echo '$g' | svr_contigs_in_genome | svr_dna_seq -fasta 1 |");
	    $contigs = &gjoseqlib::read_fasta(\*CONTIGS);
	    close(CONTIGS);
	    $parms->{-source} = "SEED";
	    use Bio::KBase::CDMI::CDMIClient;
	    use Bio::KBase::Utilities::ScriptThing;
	    use SAPserver;
	    $parms->{-sapObj} = SAPserver->new();
	}
	else
	{
	    use JSON::XS;
	    open(CONTIGS,"<$g") || die "$g is not a file that can be opened";
	    my $json = JSON::XS->new;
	    my $input_genome;
	    local $/;
	    undef $/;
	    my $input_genome_txt = <CONTIGS>;
	    $input_genome = $json->decode($input_genome_txt);
	    my $tmp = $input_genome->{contigs};
	    my @raw_contigs = map { [$_->{id},'',$_->{dna}] }  @$tmp;
	    $contigs = \@raw_contigs;
	    $parms->{-source} = "KBase";
	    use Bio::KBase::CDMI::CDMIClient;
	    use Bio::KBase::Utilities::ScriptThing;
	    $parms->{-csObj} = Bio::KBase::CDMI::CDMIClient->new_for_script();
	}
	my ($close,$coding) = &CloseGenomes::close_genomes_and_hits($contigs, $parms);
	my @tmp = @$close;
	if (@tmp > $n) { $#tmp = $n-1 }  # return the $n closest
	$return->{$g} = \@tmp;
    }
    #END close_genomes
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to close_genomes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'close_genomes');
    }
    return($return);
}




=head2 representative_sequences

  $return_1, $return_2 = $obj->representative_sequences($seq_set, $rep_seq_parms)

=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$rep_seq_parms is a rep_seq_parms
$return_1 is an id_set
$return_2 is a reference to a list where each element is an id_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
rep_seq_parms is a reference to a hash where the following keys are defined:
	existing_reps has a value which is a seq_set
	order has a value which is a string
	alg has a value which is an int
	type_sim has a value which is a string
	cutoff has a value which is a float
id_set is a reference to a list where each element is an id

</pre>

=end html

=begin text

$seq_set is a seq_set
$rep_seq_parms is a rep_seq_parms
$return_1 is an id_set
$return_2 is a reference to a list where each element is an id_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
rep_seq_parms is a reference to a hash where the following keys are defined:
	existing_reps has a value which is a seq_set
	order has a value which is a string
	alg has a value which is an int
	type_sim has a value which is a string
	cutoff has a value which is a float
id_set is a reference to a list where each element is an id


=end text



=item Description

we return two arguments.  The first is the list of representative triples,
and the second is the list of sets (the first entry always being the
representative sequence)

=back

=cut

sub representative_sequences
{
    my $self = shift;
    my($seq_set, $rep_seq_parms) = @_;

    my @_bad_arguments;
    (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"seq_set\" (value was \"$seq_set\")");
    (ref($rep_seq_parms) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"rep_seq_parms\" (value was \"$rep_seq_parms\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to representative_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'representative_sequences');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return_1, $return_2);
    #BEGIN representative_sequences
    my $options = {};
    use gjoseqlib;
    use representative_sequences;
    
    local $_;
    my($rep,$reping);
    if ($rep_seq_parms->{order}) { $options->{by_size} = $rep_seq_parms->{order} }
    if ($_ = $rep_seq_parms->{type_sim}) { $options->{sim_meas} = $_ }
    if ($_ = $rep_seq_parms->{cutoff})   { $options->{max_sim} = $_ }
    my @args = ($seq_set,$options);
    if ($_ = $rep_seq_parms->{existing_reps})
    {
	unshift(@args,$_);
    }
    if ($options->{alg})
    {
	($rep,$reping) = &representative_sequences::rep_seq_2(@args);
    }
    else
    {
	($rep,$reping) = &representative_sequences::rep_seq(@args);
    }
    $return_1 = [map { $_->[0] } @$rep];
    $return_2 = [ map { [ $_, @{ $reping->{ $_ } } ] } @$return_1 ]; 
    #END representative_sequences
    my @_bad_returns;
    (ref($return_1) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_1\" (value was \"$return_1\")");
    (ref($return_2) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_2\" (value was \"$return_2\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to representative_sequences:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'representative_sequences');
    }
    return($return_1, $return_2);
}




=head2 align_sequences

  $return = $obj->align_sequences($seq_set, $align_seq_parms)

=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$align_seq_parms is an align_seq_parms
$return is a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
align_seq_parms is a reference to a hash where the following keys are defined:
	muscle_parms has a value which is a muscle_parms_t
	mafft_parms has a value which is a mafft_parms_t
	tool has a value which is a string
	align_ends_with_clustal has a value which is an int
muscle_parms_t is a reference to a hash where the following keys are defined:
	anchors has a value which is an int
	brenner has a value which is an int
	cluster has a value which is an int
	dimer has a value which is an int
	diags has a value which is an int
	diags1 has a value which is an int
	diags2 has a value which is an int
	le has a value which is an int
	noanchors has a value which is an int
	sp has a value which is an int
	spn has a value which is an int
	stable has a value which is an int
	sv has a value which is an int
	anchorspacing has a value which is a string
	center has a value which is a string
	cluster1 has a value which is a string
	cluster2 has a value which is a string
	diagbreak has a value which is a string
	diaglength has a value which is a string
	diagmargin has a value which is a string
	distance1 has a value which is a string
	distance2 has a value which is a string
	gapopen has a value which is a string
	log has a value which is a string
	loga has a value which is a string
	matrix has a value which is a string
	maxhours has a value which is a string
	maxiters has a value which is a string
	maxmb has a value which is a string
	maxtrees has a value which is a string
	minbestcolscore has a value which is a string
	minsmoothscore has a value which is a string
	objscore has a value which is a string
	refinewindow has a value which is a string
	root1 has a value which is a string
	root2 has a value which is a string
	scorefile has a value which is a string
	seqtype has a value which is a string
	smoothscorecell has a value which is a string
	smoothwindow has a value which is a string
	spscore has a value which is a string
	SUEFF has a value which is a string
	usetree has a value which is a string
	weight1 has a value which is a string
	weight2 has a value which is a string
mafft_parms_t is a reference to a hash where the following keys are defined:
	sixmerpair has a value which is an int
	amino has a value which is an int
	anysymbol has a value which is an int
	auto has a value which is an int
	clustalout has a value which is an int
	dpparttree has a value which is an int
	fastapair has a value which is an int
	fastaparttree has a value which is an int
	fft has a value which is an int
	fmodel has a value which is an int
	genafpair has a value which is an int
	globalpair has a value which is an int
	inputorder has a value which is an int
	localpair has a value which is an int
	memsave has a value which is an int
	nofft has a value which is an int
	noscore has a value which is an int
	parttree has a value which is an int
	reorder has a value which is an int
	treeout has a value which is an int
	alg has a value which is a string
	aamatrix has a value which is a string
	bl has a value which is a string
	ep has a value which is a string
	groupsize has a value which is a string
	jtt has a value which is a string
	lap has a value which is a string
	lep has a value which is a string
	lepx has a value which is a string
	LOP has a value which is a string
	LEXP has a value which is a string
	maxiterate has a value which is a string
	op has a value which is a string
	partsize has a value which is a string
	retree has a value which is a string
	thread has a value which is a string
	tm has a value which is a string
	weighti has a value which is a string

</pre>

=end html

=begin text

$seq_set is a seq_set
$align_seq_parms is an align_seq_parms
$return is a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
align_seq_parms is a reference to a hash where the following keys are defined:
	muscle_parms has a value which is a muscle_parms_t
	mafft_parms has a value which is a mafft_parms_t
	tool has a value which is a string
	align_ends_with_clustal has a value which is an int
muscle_parms_t is a reference to a hash where the following keys are defined:
	anchors has a value which is an int
	brenner has a value which is an int
	cluster has a value which is an int
	dimer has a value which is an int
	diags has a value which is an int
	diags1 has a value which is an int
	diags2 has a value which is an int
	le has a value which is an int
	noanchors has a value which is an int
	sp has a value which is an int
	spn has a value which is an int
	stable has a value which is an int
	sv has a value which is an int
	anchorspacing has a value which is a string
	center has a value which is a string
	cluster1 has a value which is a string
	cluster2 has a value which is a string
	diagbreak has a value which is a string
	diaglength has a value which is a string
	diagmargin has a value which is a string
	distance1 has a value which is a string
	distance2 has a value which is a string
	gapopen has a value which is a string
	log has a value which is a string
	loga has a value which is a string
	matrix has a value which is a string
	maxhours has a value which is a string
	maxiters has a value which is a string
	maxmb has a value which is a string
	maxtrees has a value which is a string
	minbestcolscore has a value which is a string
	minsmoothscore has a value which is a string
	objscore has a value which is a string
	refinewindow has a value which is a string
	root1 has a value which is a string
	root2 has a value which is a string
	scorefile has a value which is a string
	seqtype has a value which is a string
	smoothscorecell has a value which is a string
	smoothwindow has a value which is a string
	spscore has a value which is a string
	SUEFF has a value which is a string
	usetree has a value which is a string
	weight1 has a value which is a string
	weight2 has a value which is a string
mafft_parms_t is a reference to a hash where the following keys are defined:
	sixmerpair has a value which is an int
	amino has a value which is an int
	anysymbol has a value which is an int
	auto has a value which is an int
	clustalout has a value which is an int
	dpparttree has a value which is an int
	fastapair has a value which is an int
	fastaparttree has a value which is an int
	fft has a value which is an int
	fmodel has a value which is an int
	genafpair has a value which is an int
	globalpair has a value which is an int
	inputorder has a value which is an int
	localpair has a value which is an int
	memsave has a value which is an int
	nofft has a value which is an int
	noscore has a value which is an int
	parttree has a value which is an int
	reorder has a value which is an int
	treeout has a value which is an int
	alg has a value which is a string
	aamatrix has a value which is a string
	bl has a value which is a string
	ep has a value which is a string
	groupsize has a value which is a string
	jtt has a value which is a string
	lap has a value which is a string
	lep has a value which is a string
	lepx has a value which is a string
	LOP has a value which is a string
	LEXP has a value which is a string
	maxiterate has a value which is a string
	op has a value which is a string
	partsize has a value which is a string
	retree has a value which is a string
	thread has a value which is a string
	tm has a value which is a string
	weighti has a value which is a string


=end text



=item Description



=back

=cut

sub align_sequences
{
    my $self = shift;
    my($seq_set, $align_seq_parms) = @_;

    my @_bad_arguments;
    (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"seq_set\" (value was \"$seq_set\")");
    (ref($align_seq_parms) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"align_seq_parms\" (value was \"$align_seq_parms\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to align_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'align_sequences');
    }

    my $ctx = $Bio::KBase::CDMI::Service::CallContext;
    my($return);
    #BEGIN align_sequences
    #END align_sequences
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to align_sequences:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'align_sequences');
    }
    return($return);
}




=head1 TYPES



=head2 annotator

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 annotation_time

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 comment

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 fid

=over 4



=item Description

A fid is a "feature id".  A feature represents an ordered list of regions from
the contigs of a genome.  Features all have types.  This allows you to speak
of not only protein-encoding genes (PEGs) and RNAs, but also binding sites,
large regions, etc.  The location of a fid is defined as a list of
"location of a contiguous DNA string" pieces (see the description of the
type "location")


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 protein_family

=over 4



=item Description

A protein_family is thought of as a set of isofunctional, homologous protein sequences.
This is not exactly what other groups have meant by "protein families".  There is no
hierarchy of super-family, family, sub-family.  We plan on loading different collections
of protein families, but in many cases there will need to be a transformation into the
concept used by Kbase.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 role

=over 4



=item Description

The concept of "role" or "functional role" is basically an atomic functional unit.
The "function of a protein" is made up of one or more roles.  That is, a bifunctional protein
with an assigned function of

   5-Enolpyruvylshikimate-3-phosphate synthase (EC 2.5.1.19) / Cytidylate kinase (EC 2.7.4.14)

would implement two distinct roles (the "function1 / function2" notation is intended to assert
that the initial part of the protein implements function1, and the terminal part of the protein
implements function2).  It is worth noting that a protein often implements multiple roles due
to broad specificity.  In this case, we suggest describing the protein function as

     function1 @ function2

That is the ' / ' separator is used to represent multiple roles implemented by distinct
domains of the protein, while ' @ ' is used to represent multiple roles implemented by
distinct domains.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 subsystem

=over 4



=item Description

A substem is composed of two components: a set of roles that are gathered to be annotated
simultaneously and a spreadsheet depicting the proteins within each genome that implement
the roles.  The set of roles may correspond to a pathway, a complex, an inventory (say, "transporters")
or whatever other principle an annotator used to formulate the subsystem.

The subsystem spreadsheet is a list of "rows", each representing the subsytem in a specific genome.
Each row includes a variant code (indicating what version of the molecular machine exists in the
genome) and cells.  Each cell is a 2-tuple:

     [role,protein-encoding genes that implement the role in the genome]

Annotators construct subsystems, and in the process impose a controlled vocabulary
for roles and functions.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 variant

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 variant_of_subsystem

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a subsystem
1: a variant

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a subsystem
1: a variant


=end text

=back



=head2 variant_subsystem_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a variant_of_subsystem
</pre>

=end html

=begin text

a reference to a list where each element is a variant_of_subsystem

=end text

=back



=head2 type_of_fid

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 types_of_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a type_of_fid
</pre>

=end html

=begin text

a reference to a list where each element is a type_of_fid

=end text

=back



=head2 length

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 begin

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 strand

=over 4



=item Description

In encodings of locations, we often specify strands.  We specify the strand
as '+' or '-'


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 contig

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 region_of_dna

=over 4



=item Description

A region of DNA is maintained as a tuple of four components:

                the contig
                the beginning position (from 1)
                the strand
                the length

           We often speak of "a region".  By "location", we mean a sequence
           of regions from the same genome (perhaps from distinct contigs).


=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: a contig
1: a begin
2: a strand
3: a length

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: a contig
1: a begin
2: a strand
3: a length


=end text

=back



=head2 location

=over 4



=item Description

a "location" refers to a sequence of regions


=item Definition

=begin html

<pre>
a reference to a list where each element is a region_of_dna
</pre>

=end html

=begin text

a reference to a list where each element is a region_of_dna

=end text

=back



=head2 locations

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a location
</pre>

=end html

=begin text

a reference to a list where each element is a location

=end text

=back



=head2 region_of_dna_string

=over 4



=item Description

we often need to represent regions or locations as
strings.  We would use something like

     contigA_200+100,contigA_402+188

to represent a location composed of two regions


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 region_of_dna_strings

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a region_of_dna_string
</pre>

=end html

=begin text

a reference to a list where each element is a region_of_dna_string

=end text

=back



=head2 location_string

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 dna

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 function

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 protein

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 md5

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 genome

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 taxonomic_group

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 annotation

=over 4



=item Description

The Kbase stores annotations relating to features.  Each annotation
is a 3-tuple:

     the text of the annotation (often a record of assertion of function)

     the annotator attaching the annotation to the feature

     the time (in seconds from the epoch) at which the annotation was attached


=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a comment
1: an annotator
2: an annotation_time

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a comment
1: an annotator
2: an annotation_time


=end text

=back



=head2 pubref

=over 4



=item Description

The Kbase will include a growing body of literature supporting protein
functions, asserted phenotypes, etc.  References are encoded as 3-tuples:

     an id (often a PubMed ID)

     a URL to the paper

     a title of the paper

The URL and title are often missing (but, can usually be inferred from the pubmed ID).


=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a string
1: a string
2: a string

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a string
1: a string
2: a string


=end text

=back



=head2 scored_fid

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a float

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a float


=end text

=back



=head2 annotations

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an annotation
</pre>

=end html

=begin text

a reference to a list where each element is an annotation

=end text

=back



=head2 pubrefs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a pubref
</pre>

=end html

=begin text

a reference to a list where each element is a pubref

=end text

=back



=head2 roles

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a role
</pre>

=end html

=begin text

a reference to a list where each element is a role

=end text

=back



=head2 optional

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 role_with_flag

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a role
1: an optional

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a role
1: an optional


=end text

=back



=head2 roles_with_flags

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a role_with_flag
</pre>

=end html

=begin text

a reference to a list where each element is a role_with_flag

=end text

=back



=head2 scored_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a scored_fid
</pre>

=end html

=begin text

a reference to a list where each element is a scored_fid

=end text

=back



=head2 proteins

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a protein
</pre>

=end html

=begin text

a reference to a list where each element is a protein

=end text

=back



=head2 functions

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a function
</pre>

=end html

=begin text

a reference to a list where each element is a function

=end text

=back



=head2 taxonomic_groups

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a taxonomic_group
</pre>

=end html

=begin text

a reference to a list where each element is a taxonomic_group

=end text

=back



=head2 subsystems

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a subsystem
</pre>

=end html

=begin text

a reference to a list where each element is a subsystem

=end text

=back



=head2 contigs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a contig
</pre>

=end html

=begin text

a reference to a list where each element is a contig

=end text

=back



=head2 md5s

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a md5
</pre>

=end html

=begin text

a reference to a list where each element is a md5

=end text

=back



=head2 genomes

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a genome
</pre>

=end html

=begin text

a reference to a list where each element is a genome

=end text

=back



=head2 pair_of_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a fid

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a fid


=end text

=back



=head2 pairs_of_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a pair_of_fids
</pre>

=end html

=begin text

a reference to a list where each element is a pair_of_fids

=end text

=back



=head2 protein_families

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a protein_family
</pre>

=end html

=begin text

a reference to a list where each element is a protein_family

=end text

=back



=head2 score

=over 4



=item Definition

=begin html

<pre>
a float
</pre>

=end html

=begin text

a float

=end text

=back



=head2 evidence

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a pair_of_fids
</pre>

=end html

=begin text

a reference to a list where each element is a pair_of_fids

=end text

=back



=head2 fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fid
</pre>

=end html

=begin text

a reference to a list where each element is a fid

=end text

=back



=head2 row

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a variant
1: a reference to a hash where the key is a role and the value is a fids

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a variant
1: a reference to a hash where the key is a role and the value is a fids


=end text

=back



=head2 fid_function_pair

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a function

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a function


=end text

=back



=head2 fid_function_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fid_function_pair
</pre>

=end html

=begin text

a reference to a list where each element is a fid_function_pair

=end text

=back



=head2 fc_protein_family

=over 4



=item Description

A functionally coupled protein family identifies a family, a score, and a function
(of the related family)


=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a protein_family
1: a score
2: a function

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a protein_family
1: a score
2: a function


=end text

=back



=head2 fc_protein_families

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fc_protein_family
</pre>

=end html

=begin text

a reference to a list where each element is a fc_protein_family

=end text

=back



=head2 allele

=over 4



=item Description

We now have a number of types and functions relating to ObservationalUnits (ous),
alleles and traits.  We think of a reference genome and a set of ous that
have measured differences (SNPs) when compared to the reference genome.
Each allele is associated with a position on a contig of the reference genome.
Prior analysis has associated traits with the alleles that impact them.
We are interested in supporting operations that locate genes in the region
of an allele (i.e., genes of the reference genome that are in a region 
containining an allele).  Similarly, we wish to locate the alleles that
impact a trait, map the alleles to regions, loacte the possibly impacted genes,
relate these to subsystems, etc.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 alleles

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an allele
</pre>

=end html

=begin text

a reference to a list where each element is an allele

=end text

=back



=head2 trait

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 traits

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a trait
</pre>

=end html

=begin text

a reference to a list where each element is a trait

=end text

=back



=head2 ou

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ous

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an ou
</pre>

=end html

=begin text

a reference to a list where each element is an ou

=end text

=back



=head2 bp_loc

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a contig
1: an int

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a contig
1: an int


=end text

=back



=head2 measurement_type

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 measurement_value

=over 4



=item Definition

=begin html

<pre>
a float
</pre>

=end html

=begin text

a float

=end text

=back



=head2 aux

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 fields

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 complex

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 complex_with_flag

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a complex
1: an optional

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a complex
1: an optional


=end text

=back



=head2 complexes_with_flags

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a complex_with_flag
</pre>

=end html

=begin text

a reference to a list where each element is a complex_with_flag

=end text

=back



=head2 complexes

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a complex
</pre>

=end html

=begin text

a reference to a list where each element is a complex

=end text

=back



=head2 name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 reaction

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 reactions

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a reaction
</pre>

=end html

=begin text

a reference to a list where each element is a reaction

=end text

=back



=head2 complex_data

=over 4



=item Description

Reactions do not connect directly to roles.  Rather, the conceptual model is that one or more roles
together form a complex.  A complex implements one or more reactions.  The actual data relating
to a complex is spread over two entities: Complex and ReactionComplex. It is convenient to be
able to offer access to the complex name, the reactions it implements, and the roles that make it up
in a single invocation.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
complex_name has a value which is a name
complex_roles has a value which is a roles_with_flags
complex_reactions has a value which is a reactions

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
complex_name has a value which is a name
complex_roles has a value which is a roles_with_flags
complex_reactions has a value which is a reactions


=end text

=back



=head2 genome_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
complete has a value which is an int
contigs has a value which is an int
dna_size has a value which is an int
gc_content has a value which is a float
genetic_code has a value which is an int
pegs has a value which is an int
rnas has a value which is an int
scientific_name has a value which is a string
taxonomy has a value which is a string
genome_md5 has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
complete has a value which is an int
contigs has a value which is an int
dna_size has a value which is an int
gc_content has a value which is a float
genetic_code has a value which is an int
pegs has a value which is an int
rnas has a value which is an int
scientific_name has a value which is a string
taxonomy has a value which is a string
genome_md5 has a value which is a string


=end text

=back



=head2 regulon

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 regulons

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a regulon
</pre>

=end html

=begin text

a reference to a list where each element is a regulon

=end text

=back



=head2 regulon_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
regulon_id has a value which is a regulon
regulon_set has a value which is a fids
tfs has a value which is a fids

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
regulon_id has a value which is a regulon
regulon_set has a value which is a fids
tfs has a value which is a fids


=end text

=back



=head2 regulons_data

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a regulon_data
</pre>

=end html

=begin text

a reference to a list where each element is a regulon_data

=end text

=back



=head2 feature_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
feature_id has a value which is a fid
genome_name has a value which is a string
feature_function has a value which is a string
feature_length has a value which is an int
feature_publications has a value which is a pubrefs
feature_location has a value which is a location

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
feature_id has a value which is a fid
genome_name has a value which is a string
feature_function has a value which is a string
feature_length has a value which is an int
feature_publications has a value which is a pubrefs
feature_location has a value which is a location


=end text

=back



=head2 expert

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 source

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 function_assertion

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: an id
1: a function
2: a source

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: an id
1: a function
2: a source


=end text

=back



=head2 function_assertions

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a function_assertion
</pre>

=end html

=begin text

a reference to a list where each element is a function_assertion

=end text

=back



=head2 atomic_regulon

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 atomic_regulon_size

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 atomic_regulon_size_pair

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: an atomic_regulon
1: an atomic_regulon_size

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: an atomic_regulon
1: an atomic_regulon_size


=end text

=back



=head2 atomic_regulon_size_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an atomic_regulon_size_pair
</pre>

=end html

=begin text

a reference to a list where each element is an atomic_regulon_size_pair

=end text

=back



=head2 atomic_regulons

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an atomic_regulon
</pre>

=end html

=begin text

a reference to a list where each element is an atomic_regulon

=end text

=back



=head2 protein_sequence

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 dna_sequence

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 name_parameter

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ss_var_role_tuple

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a subsystem
1: a variant
2: a role

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a subsystem
1: a variant
2: a role


=end text

=back



=head2 ss_var_role_tuples

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a ss_var_role_tuple
</pre>

=end html

=begin text

a reference to a list where each element is a ss_var_role_tuple

=end text

=back



=head2 genome_name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 entity_name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 weight

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 field_name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 search_hit

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a weight
1: a reference to a hash where the key is a field_name and the value is a string

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a weight
1: a reference to a hash where the key is a field_name and the value is a string


=end text

=back



=head2 correspondence

=over 4



=item Description

A correspondence is generated as a mapping of fids to fids.  The mapping
attempts to map a fid to another that performs the same function.  The
correspondence describes the regions that are similar, the strength of
the similarity, the number of genes in the chromosomal context that appear
to "correspond" and a score from 0 to 1 that loosely corresponds to 
confidence in the correspondence.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
to has a value which is a fid
iden has a value which is a float
ncontext has a value which is an int
b1 has a value which is an int
e1 has a value which is an int
ln1 has a value which is an int
b2 has a value which is an int
e2 has a value which is an int
ln2 has a value which is an int
score has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
to has a value which is a fid
iden has a value which is a float
ncontext has a value which is an int
b1 has a value which is an int
e1 has a value which is an int
ln1 has a value which is an int
b2 has a value which is an int
e2 has a value which is an int
ln2 has a value which is an int
score has a value which is an int


=end text

=back



=head2 sequence

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 seq_triple

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: an id
1: a comment
2: a sequence

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: an id
1: a comment
2: a sequence


=end text

=back



=head2 seq_set

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a seq_triple
</pre>

=end html

=begin text

a reference to a list where each element is a seq_triple

=end text

=back



=head2 id_set

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an id
</pre>

=end html

=begin text

a reference to a list where each element is an id

=end text

=back



=head2 rep_seq_parms

=over 4



=item Description

fractions or bits


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
existing_reps has a value which is a seq_set
order has a value which is a string
alg has a value which is an int
type_sim has a value which is a string
cutoff has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
existing_reps has a value which is a seq_set
order has a value which is a string
alg has a value which is an int
type_sim has a value which is a string
cutoff has a value which is a float


=end text

=back



=head2 muscle_parms_t

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
anchors has a value which is an int
brenner has a value which is an int
cluster has a value which is an int
dimer has a value which is an int
diags has a value which is an int
diags1 has a value which is an int
diags2 has a value which is an int
le has a value which is an int
noanchors has a value which is an int
sp has a value which is an int
spn has a value which is an int
stable has a value which is an int
sv has a value which is an int
anchorspacing has a value which is a string
center has a value which is a string
cluster1 has a value which is a string
cluster2 has a value which is a string
diagbreak has a value which is a string
diaglength has a value which is a string
diagmargin has a value which is a string
distance1 has a value which is a string
distance2 has a value which is a string
gapopen has a value which is a string
log has a value which is a string
loga has a value which is a string
matrix has a value which is a string
maxhours has a value which is a string
maxiters has a value which is a string
maxmb has a value which is a string
maxtrees has a value which is a string
minbestcolscore has a value which is a string
minsmoothscore has a value which is a string
objscore has a value which is a string
refinewindow has a value which is a string
root1 has a value which is a string
root2 has a value which is a string
scorefile has a value which is a string
seqtype has a value which is a string
smoothscorecell has a value which is a string
smoothwindow has a value which is a string
spscore has a value which is a string
SUEFF has a value which is a string
usetree has a value which is a string
weight1 has a value which is a string
weight2 has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
anchors has a value which is an int
brenner has a value which is an int
cluster has a value which is an int
dimer has a value which is an int
diags has a value which is an int
diags1 has a value which is an int
diags2 has a value which is an int
le has a value which is an int
noanchors has a value which is an int
sp has a value which is an int
spn has a value which is an int
stable has a value which is an int
sv has a value which is an int
anchorspacing has a value which is a string
center has a value which is a string
cluster1 has a value which is a string
cluster2 has a value which is a string
diagbreak has a value which is a string
diaglength has a value which is a string
diagmargin has a value which is a string
distance1 has a value which is a string
distance2 has a value which is a string
gapopen has a value which is a string
log has a value which is a string
loga has a value which is a string
matrix has a value which is a string
maxhours has a value which is a string
maxiters has a value which is a string
maxmb has a value which is a string
maxtrees has a value which is a string
minbestcolscore has a value which is a string
minsmoothscore has a value which is a string
objscore has a value which is a string
refinewindow has a value which is a string
root1 has a value which is a string
root2 has a value which is a string
scorefile has a value which is a string
seqtype has a value which is a string
smoothscorecell has a value which is a string
smoothwindow has a value which is a string
spscore has a value which is a string
SUEFF has a value which is a string
usetree has a value which is a string
weight1 has a value which is a string
weight2 has a value which is a string


=end text

=back



=head2 mafft_parms_t

=over 4



=item Description

linsi | einsi | ginsi | nwnsi | nwns | fftnsi | fftns (D)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
sixmerpair has a value which is an int
amino has a value which is an int
anysymbol has a value which is an int
auto has a value which is an int
clustalout has a value which is an int
dpparttree has a value which is an int
fastapair has a value which is an int
fastaparttree has a value which is an int
fft has a value which is an int
fmodel has a value which is an int
genafpair has a value which is an int
globalpair has a value which is an int
inputorder has a value which is an int
localpair has a value which is an int
memsave has a value which is an int
nofft has a value which is an int
noscore has a value which is an int
parttree has a value which is an int
reorder has a value which is an int
treeout has a value which is an int
alg has a value which is a string
aamatrix has a value which is a string
bl has a value which is a string
ep has a value which is a string
groupsize has a value which is a string
jtt has a value which is a string
lap has a value which is a string
lep has a value which is a string
lepx has a value which is a string
LOP has a value which is a string
LEXP has a value which is a string
maxiterate has a value which is a string
op has a value which is a string
partsize has a value which is a string
retree has a value which is a string
thread has a value which is a string
tm has a value which is a string
weighti has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
sixmerpair has a value which is an int
amino has a value which is an int
anysymbol has a value which is an int
auto has a value which is an int
clustalout has a value which is an int
dpparttree has a value which is an int
fastapair has a value which is an int
fastaparttree has a value which is an int
fft has a value which is an int
fmodel has a value which is an int
genafpair has a value which is an int
globalpair has a value which is an int
inputorder has a value which is an int
localpair has a value which is an int
memsave has a value which is an int
nofft has a value which is an int
noscore has a value which is an int
parttree has a value which is an int
reorder has a value which is an int
treeout has a value which is an int
alg has a value which is a string
aamatrix has a value which is a string
bl has a value which is a string
ep has a value which is a string
groupsize has a value which is a string
jtt has a value which is a string
lap has a value which is a string
lep has a value which is a string
lepx has a value which is a string
LOP has a value which is a string
LEXP has a value which is a string
maxiterate has a value which is a string
op has a value which is a string
partsize has a value which is a string
retree has a value which is a string
thread has a value which is a string
tm has a value which is a string
weighti has a value which is a string


=end text

=back



=head2 align_seq_parms

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
muscle_parms has a value which is a muscle_parms_t
mafft_parms has a value which is a mafft_parms_t
tool has a value which is a string
align_ends_with_clustal has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
muscle_parms has a value which is a muscle_parms_t
mafft_parms has a value which is a mafft_parms_t
tool has a value which is a string
align_ends_with_clustal has a value which is an int


=end text

=back



=cut

1;
