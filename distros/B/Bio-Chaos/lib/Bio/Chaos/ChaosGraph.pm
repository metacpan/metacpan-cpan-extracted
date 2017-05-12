# $Id: ChaosGraph.pm,v 1.7 2005/06/15 16:21:09 cmungall Exp $
#
#

=head1 NAME

  Bio::Chaos::ChaosGraph     - object for representing a chaos-xml dataset

=head1 SYNOPSIS

  use Bio::Chaos::ChaosGraph;
  use Data::Stag;

  my $chaos_node = Data::Stag->parse('Rab1.chaos');
  my $cg = Bio::Chaos::ChaosGraph->new($chaos_node);
  
  my $fl = $cg->top_features;
  foreach my $f (@$fl) {
    next unless $f->get_type eq 'gene';
    $island_feature = $cg->make_gene_island($f, 5000, 5000);

    print $island_feature->xml;
  }

=head1 DESCRIPTION

This class allows manipulation of in-memory Chaos documents as
L<Data::Stag> nodes, and provides additional methods for traversing
the graph structure defined in the Chaos document

=head1 SEE ALSO

The L<cx-genbank2chaos.pl> script

The L<Bio::Chaos> helper module

The BioPerl L<Bio::SeqIO::chaosxml> writer

=cut

package Bio::Chaos::ChaosGraph;

use Exporter;
use Data::Stag qw(:all);
use Bio::Chaos::Root;
@ISA = qw(Bio::Chaos::Root Exporter);

use FileHandle;
use strict;
use Graph;

# Constructor


=head2 new

  Usage   - my $chaos = Bio::Chaos::ChaosGraph->new($chaos_stag)
  Returns - Bio::Chaos::ChaosGraph

creates a new Chaos::ChaosGraph object

=cut

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = bless {}, $class;
    my ($stag,$file,$fmt) =
      $self->_rearrange([qw(stag file fmt)], @_);
    if ($stag && $file) {
        $self->freak("use -stag OR -file as arguments");
    }
    #my @g_opt = (compat02=>1);
    my @g_opt = ();
    $self->graph(Graph->new(@g_opt));
    $self->locgraph(Graph->new(@g_opt));
    $self->feature_idx({});
    $self->init_from_stag($stag) if $stag;
    $self->init_from_file($file,$fmt) if $file;
    return $self;
}


=head2 init_from_stag

  Usage   - $cg->init_from_stag($chaos_node);
  Returns -
  Args    - L<Data::Stag>

sets up a CG object from a stag node conforming to the Chaos-XML schema

  my $cg = Bio::Chaos::ChaosGraph->new;
  my $cn = Data::Stag->parse("mydata.chaos.xml");
  $cg->init_from_stag($cn);

=cut

sub init_from_stag {
    my $self = shift;
    my $stag = shift;
    if (!$stag) {
	$self->freak;
    }
    my $verbose = $self->verbose;
    $self->debug("Adding features") if $verbose; 
    foreach my $feature ($stag->get_feature) {
	$self->add_feature($feature);
    }
    $self->debug("Features added") if $verbose; 
    $self->debug("Adding feature_relationships") if $verbose; 
    foreach my $fr ($stag->get_feature_relationship) {
	$self->add_feature_relationship($fr);
    }
    $self->debug("Feature_relationships added") if $verbose; 
    return;
}

=head2 init_from_file

  Usage   - $cg->init_from_file($chaos_node);
  Returns -
  Args    - filename string

sets up a CG object from a file conforming to the Chaos-XML schema

  my $cg = Bio::Chaos::ChaosGraph->new;
  $cg->init_from_file("mydata.chaos.xml");

=cut

sub init_from_file {
    my $self = shift;
    my $file = shift;
    my $fmt = shift;
    if (!$fmt) {
        if ($file =~ /chaos/) {
            $fmt = 'chaos';
        }
        else {
            $fmt = 'genbank';
        }
    }
    if ($fmt eq 'chaos') {
        my $stag = Data::Stag->parse($file);
	$self->init_from_stag($stag);
        return;
    }
    $self->chaos_flavour("$fmt-unflattened");
    $self->load_module("Bio::SeqIO");
    my $unflattener = $self->unflattener;
    my $type_mapper = $self->type_mapper;
    my $seqio =
      Bio::SeqIO->new(-file=> $file,
                      -format => $fmt);
    while (my $seq = $seqio->next_seq()) {
	$unflattener->unflatten_seq(-seq=>$seq,
				    -use_magic=>1);
	$type_mapper->map_types_to_SO(-seq=>$seq);
	my $outio = Bio::SeqIO->new( -format => 'chaos');
	$outio->write_seq($seq);
	my $stag = $outio->handler->stag;
	$self->init_from_stag($stag);
    }
    $self->name_all_features;
    return;
}

# --- turns object into stag document ---

=head2 stag

 Usage   - my $chaos_node = $cg->stag;
 Returns - L<Data::Stag>
 Args    -

Generates a L<Data::Stag> object conforming to Chaos-XML dtd

=cut

sub stag {
    my $self = shift;
    my $W = Data::Stag->makehandler;
    $self->fire_events($W);
    return $W->stag;
}

sub chaos_flavour {
    my $self = shift;
    $self->{_chaos_flavour} = shift if @_;
    return $self->{_chaos_flavour} || 'chaos';
}

sub metadata {
    my $self = shift;
    $self->{_metadata} = shift if @_;
    return $self->{_metadata};
}


sub fire_events {
    my $self = shift;
    my $W = shift;

    my $t = time;
    my $ppt = localtime($t);
    my $prog = $0;
    chomp $prog;

    my @meta = $self->metadata ? ($self->metadata) : ();
    $W->start_event('chaos');
    $W->event(chaos_metadata=>[
			       [chaos_version=>1],
			       [chaos_flavour=>$self->chaos_flavour],
			       @meta,
			       
			       [feature_unique_key=>'feature_id'],
			       [equiv_chado_release=>'chado_1_01'],
			       
			       [export_unixtime=>$t],
			       [export_localtime=>$ppt],
			       [export_host=>$ENV{HOST}],
			       [export_user=>$ENV{USER}],
			       [export_perl5lib=>$ENV{PERL5LIB}],
			       [export_program=>$prog],
			      ]
	     );
    my $g = $self->graph;

    # unordered; features followed by frs
    my $done_idx = {};
    my @ufeats = @{$self->unlocalised_features};
    $self->fire_feature_event($W, $_, $done_idx) foreach @ufeats;
    
    $W->end_event('chaos');
}

sub fire_feature_event {
    my $self = shift;
    my $W = shift           || $self->freak("no writer");
    my $f = shift           || $self->freak("no feature"); 
    my $done_idx = shift    || $self->freak("no index of done features");
    my $fid = $f->get_feature_id;
    return if $done_idx->{$fid};

    my $g = $self->graph;
    my @in_edges = $g->edges_from($fid); # object FRs
    my @frs = ();
    while (my $edge = shift @in_edges) { 
        my ($subject_id,$object_id) = @$edge;
	my $type = $g->get_edge_attribute(@$edge,'type');
	my $rank = $g->get_edge_attribute(@$edge,'rank');

        if (!$self->feature_idx->{$object_id}) {
            $f->add_featureprop([[type=>'comment'],[value=>"this feature has a parent in another subgraph; there will be a trailing object_id=$object_id"]]);
            # this is the case for AceView worm models and
            # dicistronic genes where exons are shared across genes
        }
        else {
            # objects must be written before subjects
            $self->fire_feature_event($W,
                                      $self->feature_idx->{$object_id},
                                      $done_idx);
        }
	# no point carrying on, redundant tree traversal
	return if $done_idx->{$fid};
	push(@frs,
	     [feature_relationship=>[
				     [subject_id=>$subject_id],
				     [object_id=>$object_id],
				     [type=>$type],
				     [rank=>$rank],
				    ]]);
    }
    return if $done_idx->{$fid};

    $W->event(feature=>$f->data);
    $W->event(@$_) foreach @frs;
    $done_idx->{$fid} = 1;
    my @nextfs = 
      (@{$self->get_features_on($f)},
       @{$self->get_features_contained_by($f)});
#    print "$fid has the following: @nextfs\n";
    $self->fire_feature_event($W, $_, $done_idx) foreach @nextfs;
    return;
}


sub init_mldbm {
    my $self = shift;
    require "MLDBM.pm";
    import("MLDBM", qw(DB_File Storable));
    return;
}


# deprecated?
sub next_idn {
    my $self = shift;
    $self->{_next_idn} = shift if @_;
    return $self->{_next_idn};
}


# deprecated?
sub generate_new_feature_id {
    my $self = shift;
    my $prefix = shift || 'feature';
    my $feature_id;
    my $idn = $self->{_next_idn} || 0;
    my $fidx = $self->feature_idx;
    while (!$feature_id) {
	$idn++;
	unless ($fidx->{"$prefix-$idn"}) {
	    $feature_id = "$prefix-$idn";
	}
    }
    $self->{_next_idn} = $idn;
    return $feature_id;
}


=head2 unflattener

  Usage   - my $unf = $cg->unflattener;
  Usage   - $cg->unflattener(Bio::SeqFeature::Tools::Unflattener->new);
  Returns - L<Bio::SeqFeature::Tools::Unflattener>
  Args    - L<Bio::SeqFeature::Tools::Unflattener> (OPTIONAL)

gets/sets the object that the CG will use for unflattening genbank
seqs. See bioperl docs for details

=cut

sub unflattener {
    my $self = shift;
    $self->{_unflattener} = shift if @_;
    if (!$self->{_unflattener} ) {
	$self->load_module("Bio::SeqFeature::Tools::Unflattener");
	$self->{_unflattener} =
	  Bio::SeqFeature::Tools::Unflattener->new;
    }
    return $self->{_unflattener};
}

=head2 type_mapper

  Usage   - my $unf = $cg->type_mapper;
  Usage   - $cg->type_mapper(Bio::SeqFeature::Tools::Type_mapper->new);
  Returns - L<Bio::SeqFeature::Tools::Type_mapper>
  Args    - L<Bio::SeqFeature::Tools::Type_mapper> (OPTIONAL)

gets/sets the object that the CG will use for mapping genbank types to
SO. See bioperl docs for details

=cut

sub type_mapper {
    my $self = shift;
    $self->{_type_mapper} = shift if @_;
    if (!$self->{_type_mapper} ) {
	$self->load_module("Bio::SeqFeature::Tools::TypeMapper");
	$self->{_type_mapper} =
	  Bio::SeqFeature::Tools::TypeMapper->new;
    }
    return $self->{_type_mapper};
}



=head2 feature_idx

 Usage   - my $f = $cg->feature_idx->{$feature_id}
 Returns - hashref, keyed by feature ID
 Args    - 

index hash for looking up feature stag nodes by ID

The ID is the value of feature/feature_id in the chaos-xml structure

the hash has values that are chaos L<Data::Stag> nodes, and can be
accessed using normal stag methods/functions

=cut

sub feature_idx {
    my $self = shift;
    $self->{_feature_idx} = shift if @_;
    return $self->{_feature_idx};
}


=head2 get_feature

 Usage   - my $f = $cg->get_feature($feature_id)
 Returns - L<Data::Stag> conforming to Chaos-xml feature element
 Args    - id string

look up feature stag nodes by ID

The ID is the value of feature/feature_id in the chaos-xml structure

The returned L<Data::Stag> node is a feature node/element, and can be
accessed using normal stag methods/functions

=cut

sub get_feature {
    my $self = shift;
    my $fid = shift;
    return $self->{_feature_idx}->{$fid};
}

# relationship graph
# equiv to chaos/chado feature_relationship graph

=head2 graph

  Usage   - my $graph = $cg->graph;
  Returns - L<Graph>
  Args    -

gets/sets the L<Graph> object which corresponds to the graph defined
by the chado/chaos feature_relationships. The sink of the graph is the
root (eg genes), the source of the graph is the leaves (eg exons).

The graph labels contain the relationship type and the rank

You should not need to manipulate the Graph object directly - this is
mostly used internally, but is made public to allow inspection of the
graph using the native L<Graph> methods

=cut

sub graph {
    my $self = shift;
    $self->{_graph} = shift if @_;
    return $self->{_graph};
}

=head2 graph

  Usage   - my $locgraph = $cg->locgraph;
  Returns - L<Graph>
  Args    -

gets/sets the L<Graph> object which corresponds to the graph defined
by the chado/chaos featurelocs. 

The graph labels contain the nbeg, nend, rank, group

You should not need to manipulate the L<Graph> object directly - this is
mostly used internally, but is made public to allow inspection of the
graph using the native L<Graph> methods

=cut

sub locgraph {
    my $self = shift;
    $self->{_locgraph} = shift if @_;
    return $self->{_locgraph};
}


=head2 add_feature

 Usage   - $cg->add_feature($f);
 Returns -
 Args    - L<Data::Stag> [feature node]

=cut

sub add_feature {
    my $self = shift;
    my $feature = shift;
    my $fid = $feature->get_feature_id;

    my $verbose = $self->verbose;

    $self->graph->add_vertex($fid);
    $self->feature_idx->{$fid} = $feature;
    my @flocs = $feature->get_featureloc;
    foreach my $floc (@flocs) {
	$self->add_featureloc($fid, $floc);
    }
    $self->debug("added feature: $fid") if $verbose;
    return 1;
}

=head2 add_featureloc

 Usage   - $cg->add_featureloc($fl);
 Returns -
 Args    - L<Data::Stag> [featureloc node]

=cut

sub add_featureloc {
    my $self = shift;
    my $fid = shift;
    my $floc = shift;
    my $lg = $self->locgraph;

    my $verbose = $self->verbose;

    my $src_fid = $floc->get_srcfeature_id;
    $lg->add_edge($fid,$src_fid);
    $self->debug("added featureloc: $fid to $src_fid") if $verbose;
    return;
}


=head2 replace_featureloc

  Usage   - $cg->replace_featureloc($f,$fl_old,$fl_new);
  Returns -
  Args    - feature L<Data::Stag> [feature node]
            old loc L<Data::Stag> [featureloc node]
            new loc L<Data::Stag> [featureloc node]

=cut

sub replace_featureloc {
    my $self = shift;
    my $feature = shift;
    my $old_floc = shift;
    my $new_floc = shift;

    my $verbose = $self->verbose;

    my $lg = $self->locgraph;
    my $fid = $feature->get_feature_id;

    my $old_src_fid = $old_floc->get_srcfeature_id;
    my $new_src_fid = $new_floc->get_srcfeature_id;

    my @new_e = ($fid,$new_src_fid);
    $lg->delete_edge($fid, $old_src_fid);
    $lg->add_edge(@new_e);
    foreach ($new_floc->kids) {
        next unless $_->isterminal;
        next if $_->name eq 'srcfeature_id';
        $lg->set_edge_attribute(@new_e,
                                $_->name,
                                $_->data);
    }
    $feature->set_featureloc($new_floc->data);
    $self->debug("replaced featureloc: $fid to $new_src_fid") if $verbose;
    return;
}

=head2 add_feature_relationship

 Usage   - $cg->add_feature_relationship($f);
 Returns -
 Args    - L<Data::Stag> [feature_relationship node]

=cut

sub add_feature_relationship {
    my $self = shift;
    my $fr = shift;
    my $g = $self->graph;
    my %frh = $fr->pairs;
    # FROM subject TO object
    # (this means subject is source, object is sink)
    my @edge = ($frh{subject_id},
                $frh{object_id});

    my $verbose = $self->verbose;

    if (!$edge[0] || !$edge[1]) {
	$self->freak("bad feature_rel", $fr);
    }
    $g->add_edge(@edge);
    $g->set_edge_attribute(@edge,
                           "type",
                           $frh{type} || '');
    $g->set_edge_attribute(@edge,
                           "rank",
                           $frh{rank} || '0');

    $self->debug("added fr: @edge") if $verbose;
    return 1;
}



=head2 top_features

  Usage   - my $features = $cg->top_features;
  Returns - listref of L<Data::Stag> feature nodes
  Args    -

returns features at the root of the feature graph (typically genes,
but also "simple" features that are not attached other features via
feature_relationships, such as SNPs, contigs, etc

Formally, a feature F is a top feature if there is no
feature_relationship R with R.subject_id = F

=cut

sub top_features {
    my $self = shift;
    my $g = $self->graph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!$g->edges_from($fid)) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}


=head2 leaf_features

  Usage   - my $features = $cg->leaf_features;
  Returns - listref of L<Data::Stag> feature nodes
  Args    -

returns features at the leaves of the feature graph (with gene model
subgraphs, these may be exons and polypeptides - or "simple" features
that are not attached other features via feature_relationships, such
as SNPs, contigs, etc)

Formally, a feature F is a leaf feature if there is no
feature_relationship R with R.object_id = F

=cut

sub leaf_features {
    my $self = shift;
    my $g = $self->graph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!$g->edges_to($fid)) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}


=head2 unlocalised_features

  Usage   - my $topfs = $cg->unlocalised_features;
  Synonym - unlocalized_features
  Returns - listref of L<Data::Stag> feature nodes
  Args    -

returns features at the root of the featureloc graph, ie unlocalised
features.

Formally, a feature F is unlocalised if it contains no featurelocs


=cut

sub unlocalised_features {
    my $self = shift;
    my $lg = $self->locgraph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!$lg->edges_from($fid)) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}
*unlocalized_features = \&unlocalised_features;

=head2 top_unlocalised_features

  Usage   - my $topfs = $cg->top_unlocalised_features;
  Synonym - top_unlocalized_features
  Returns - listref of L<Data::Stag> feature nodes
  Args    -

Returns the intersection of the set of all unlocalised features and
all top features

=cut

sub top_unlocalised_features {
    my $self = shift;
    my $g = $self->graph;
    my $lg = $self->locgraph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!$g->edges_from($fid) &&
	    !$lg->edges_from($fid)) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}
*top_unlocalized_features = \&top_unlocalised_features;


=head2 get_features_on

  Usage   - my $features = $cg->get_features_on($contig_feature)
  Returns - listref of L<Data::Stag> feature nodes
  Args    - L<Data::Stag> feature node OR id string

all features DIRECTLY localised to a particular feature

=cut

sub get_features_on {
    my $self = shift;
    my $srcf = shift;

    my $srcfid = ref($srcf) ? $srcf->get_feature_id : $srcf;
    my $lg = $self->locgraph;

    my @edges = $lg->edges_to($srcfid);
    my @located_fids = ();
    while (my $edge = shift @edges) {
	push(@located_fids, $edge->[0]);
    }
    my $fidx = $self->feature_idx;
    return [map {$fidx->{$_}} @located_fids];
}


=head2 get_features_contained_by

  Usage   - my $transcripts = $cg->get_features_contained_by($gene_feature)
  Returns - listref of L<Data::Stag> feature nodes
  Args    - L<Data::Stag> feature node

all features contained by another feature, where containment is
defined by any feature_relationship, with the container being the
object_id and the containee being the
subject_id. feature_relationship.type is ignored

=cut

sub get_features_contained_by {
    my $self = shift;
    my $f = shift;

    my $g = $self->graph;

    my @edges = $g->edges_to($f->get_feature_id);
    my @contained_fids = ();
    while (my $edge = shift @edges) {
	push(@contained_fids, $edge->[0]);
    }
    my $fidx = $self->feature_idx;
    return [map {$fidx->{$_}} @contained_fids];
}

=head2 get_features_containing

  Usage   - my $transcripts = $cg->get_features_containing($exon_feature)
  Returns - listref of L<Data::Stag> feature nodes
  Args    - L<Data::Stag> feature node

all features containing by another feature, where containment is
defined by any feature_relationship, with the container being the
object_id and the containee being the
subject_id. feature_relationship.type is ignored

=cut

sub get_features_containing {
    my $self = shift;
    my $f = shift;

    my $g = $self->graph;

    my @edges = $g->edges_from($f->get_feature_id);
    my @container_fids = ();
    while (my $edge = shift @edges) {
	push(@container_fids, $edge->[1]);
    }
    my $fidx = $self->feature_idx;
    return [map {$fidx->{$_}} @container_fids];
}


=head2 get_all_contained_features

  Usage   - my $features = $cg->get_all_contained_features($gene_feature)
  Returns - listref of L<Data::Stag> feature nodes
  Args    - L<Data::Stag> feature node

As get_features_contained_by, but performs the transitive closure - eg
for a gene will fetch transcriipts, and the transcripts subfeatures
(exons) into one flat list

=cut

sub get_all_contained_features {
    my $self = shift;
    my $top = shift || $self->freak("requires parameter: top [feature]");
    my $topfid = $top->get_feature_id;
    my $fidx = $self->feature_idx;

    my $verbose = $self->verbose;

    $self->debug("get_all_contained_features $topfid") if $verbose;

    my $iterator = $self->feature_iterator($topfid);
    my @cfids = ();
    my %got_idh = ();
    while (my $fid = $iterator->next_vertex) {
        $self->debug("iterator; next=$fid") if $verbose;
        next if $got_idh{$fid};
        $got_idh{$fid} = 1;
	push(@cfids, $fid) unless $fid eq $topfid;
    }
    return [map {$fidx->{$_}} @cfids];
}



=head2 feature_relationships_for_subject

 Usage   - $frs = $cg->get_feature_relationships_for_subject($exon_id);
 Returns - listref of L<Data::Stag> feature_relationship nodes
 Args    - L<Data::Stag> feature node OR id string

find the feature_relationship nodes with a particular subject_id

=cut

sub feature_relationships_for_subject {
    my $self = shift;
    my $f = shift;
    my $fid = ref($f) ? $f->get_feature_id : $f;

    my $g = $self->graph;

    my @edges = $g->edges_from($fid);
    my @frs = ();
    while (my $edge = shift @edges) {
	if (!$edge->[0] || !$edge->[1]) {
	    $self->freak("bad edge: [@$edge]", $f);
	}
	my $type = $g->get_edge_attribute(@$edge,'type');
	push(@frs, 
	     Data::Stag->new(feature_relationship=>[
						    [subject_id=>$edge->[0]],
						    [object_id=>$edge->[1]],
						    [type=>$type],
						   ]));
    }
    return [@frs];
}


sub get_floc {
    my $self = shift;
    my $f = shift;

    my @flocs = $f->get_featureloc;
    if (@flocs > 1) {
	@flocs = grep {!$_->get_rank && !$_->get_locgroup} @flocs;
	if (@flocs > 1) {
	    $self->freak("invalid flocs", @flocs);
	}
    }
    return shift @flocs;
}


=head2 make_gene_islands

 Usage   - my $contigs = $cg->make_gene_islands;
 Returns - listref of L<Data::Stag> feature nodes
 Args    -

create a contig feature for every gene, and transform the gene and all
the subfeatures of gene onto that contig

=cut

sub make_gene_islands {
    my $self = shift;
    my @args = @_;
    my $fs = $self->top_features;
    my @islands = ();
    foreach my $f (@$fs) {
	my $type = $f->get_type;
	$self->freak("no type", $f) unless $type;
	next unless $f->get_type eq 'gene';
	my $island = $self->make_island($f, @args);
	push(@islands, $island);
    }
    return \@islands;
}

# generates an island contig around a feature $f and transforms the
# coordinates to the contig
sub make_island {
    my $self = shift;
    my $f = shift;

    my $verbose = $self->verbose;
    my ($left, $right) = @_;
    if (!$left) {
	$left = 0;
    }
    if (!$right) {
	$right = $left;
    }
    my $floc = $self->get_floc($f);
    if (!$floc) {
	$self->freak("No featureloc", $f);
    }
    my $src_fid = $floc->get_srcfeature_id;
    my $srcf = $self->get_feature($src_fid);
    my $strand = $floc->get_strand;

    my $nbeg = $floc->get_nbeg - $left * $strand;
    my $nend = $floc->get_nend + $right * $strand;
#    my $island_id = $self->generate_new_feature_id('contig');
    my $island_id = "contig:$src_fid:$nbeg:$nend";

    my $island_name = 'contig-'.$f->get_name.'-'.$left.'-'.$right;
    my $island_uniquename = 'contig-'.$f->get_uniquename.'-'.$left.'-'.$right; 
    $self->debug("making island $island_name") if $verbose;

    my $island =
      $self->new_feature(
			 feature_id=>$island_id,
			 name=>$island_name,
			 uniquename=>$island_uniquename,
			 type=>'contig',
			 featureloc=>[
				      nbeg=>$nbeg,
				      nend=>$nend,
                                      strand=>$strand,
				      srcfeature_id=>$src_fid,
				     ],
			);
    $self->debug("deriving residues $island_name") if $verbose;
    $self->derive_residues($island);
    $self->add_feature($island);
    $self->debug("performing main loctransform $island_name") if $verbose;
    $self->loctransform($f,
			$island);
    my $children = $self->get_all_contained_features($f);
    # replicate feature and add to subhraph
    # (we wish to replicate because a feature can be
    #  shared between graphs and we want to do loctransforms
    #  on the features on a per-subgraph basis)
    $children = [map {$_->duplicate} @$children];

    $self->debug("performing subfeatures loctransform $island_name [total %s]",
          scalar(@$children)) if $verbose;
    foreach my $child (@$children) {
	$self->loctransform($child, $island);
    }
    $self->debug("creating new chaos graph for island $island_name") if $verbose;
    my $C = $self->new; # create a new subgraph
    my @feats = ($srcf, $island, $f, @$children);
    foreach my $subf (@feats) {
	$C->add_feature($subf);
	my $frs = $self->feature_relationships_for_subject($subf);
	$C->add_feature_relationship($_) foreach @$frs;
    }
    $self->debug("new chaos graph created for island $island_name") if $verbose;
    return $C;
}


=head2 derive_residues

 Usage   - my $ok = $cg->derive_residues($feature);
 Returns - sequence string
 Returns - L<Data::Stag> feature node

splices out the residues from the srcfeature and sets the
feature/residues element (does not return the actual residues)

=cut

sub derive_residues {
    my $self = shift;
    my $feature = shift;
    my $res;
    if ($self->is_spliced($feature)) {
        $self->freak('not yet');
    }
    else {
        my @flocs = $feature->get_featureloc;
	if (!@flocs) {
	    $self->freak("feature is not located, can't derive residues",
			 $feature);
	}
        @flocs = grep {!$_->get_rank} @flocs;
        $self->freak unless @flocs;
        my @resl =
          map {
	      my $src_fid = $_->get_srcfeature_id;
              my $srcf = $self->get_feature($src_fid);
	      if (!$srcf) {
		  $self->freak("no source feature for $src_fid in feature",
			       $feature);
	      }
              my $srcres = $srcf->get_residues;
	      if (!$srcres) {
		  $self->freak("feature $src_fid has no residues", $srcf);
	      }
              $self->cutseq($srcres, $_->get_nbeg, $_->get_nend);
          } @flocs;
        $res = shift @resl;
        if (@resl) {
            foreach (@resl) {
                if ($_ ne $res) {
                    $self->freak("$_ ne $res");
                }
            }
        }
        
    }
    $self->freak("cannot derive residues", $feature) unless defined $res;
    $feature->set_residues($res);
    return 1;
}

sub cutseq {
    my $self = shift;
    my $res = shift;
    my $nbeg = shift;
    my $nend = shift;
    if ($nbeg <= $nend) {
        return substr($res, $nbeg, $nend-$nbeg);
    }
    else {
        my $cut = substr($res, $nend, $nbeg-$nend);
        $cut = $self->revcomp($cut);
        return $cut;
    }
}

sub revcomp {
    my $self = shift;
    my $res = shift;
    $res =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
    return scalar(CORE::reverse($res));
}


=head2 loctransform

 Usage   - $cg->loctransform($gene,$contig);
 Args    - source L<Data::Stag> feature node
           target L<Data::Stag> feature node

replaces the featureloc(s) of a feature with new featureloc(s)
relative to the target feature - eg going from chromosome to contig

=cut

sub loctransform {
    my $self = shift;
    my $sfeature = shift;                    # source  (eg gene)
    my $tfeature = shift;                    # target  (eg contig)

    my $verbose = $self->verbose;

    # get source and target feature locations;
    # any feature can have >1 flocs (differentiated by rank, group)
    # (usually there will be just 1 each)
    my @sflocs = $sfeature->get_featureloc;
    my @tflocs = $tfeature->get_featureloc;

    $self->debug("  loctransform srcs:%s targets:%s",
                 scalar(@sflocs),scalar(@tflocs)) if $verbose;
    # the source and target locations we use to actually transform
    my $sfloc;
    my $tfloc;
    my $ssrc_fid;
    my $tsrc_fid;

    my $already_transformed;
    # ASSERTION:
    # forall (@sflocs, @tflocs)
    #     there exists exactly one pair ($sfloc, $tfloc)
    #     such that $sfloc and $tfloc share the same srcfeature_id
    #
    # this pair is the source and target flocs that will be used in
    # the location transform
    foreach my $sflocI (@sflocs) {
        my $ssrc_fidI = $sflocI->get_srcfeature_id;
        if ($ssrc_fidI eq $tfeature->get_feature_id) {
            $already_transformed = 1;
            last;
        }
        foreach my $tflocI (@tflocs) {
            my $tsrc_fidI = $tflocI->get_srcfeature_id;
            # intersection
            if ($ssrc_fidI eq $tsrc_fidI) {
                if ($sfloc || $tfloc) {
                    $self->freak("CONFLICT: >1 pair [$ssrc_fid, $tsrc_fid]",
                                 $sfloc, $tfloc);
                }
                $sfloc = $sflocI;
                $tfloc = $tflocI;
                $ssrc_fid = $ssrc_fidI;
                $tsrc_fid = $tsrc_fidI;
            }
        }
    }

    if ($already_transformed) {
        # nothing to be done
        return;
    }

    # ASSERTION (see above) - at least 1 pair
    if (!($sfloc || $tfloc)) {
        $self->freak("NO LOC PAIR FOUND",
                     @sflocs, @tflocs,$sfeature,$tfeature);
    }


    # s: source
    # t: target

    my $snbeg = $sfloc->get_nbeg;
    my $snend = $sfloc->get_nend;
    my $srank = $sfloc->get_rank;
    my $sstrand = $sfloc->get_strand;
    my $tnbeg = $tfloc->get_nbeg;
    my $tnend = $tfloc->get_nend;
    my $tstrand = $tfloc->get_strand;

    my $tfid = $tfeature->get_feature_id;
    if (!$tfid) {
	$self->freak("NO FEATURE_ID", $tfeature);
    }

    $snbeg = ($snbeg - $tnbeg) * $tstrand;
    $snend = ($snend - $tnbeg) * $tstrand;

    $self->debug("    new floc: %s..%s on %s",
                 $snbeg,$snend,$tfid)
      if $verbose;

    my $nu_sfloc =
      $self->new_featureloc(srcfeature_id=>$tfid,
                            nbeg=>$snbeg,
                            nend=>$snend,
                            strand=>$sstrand,
                            rank=>$srank,
                           );
    $self->replace_featureloc($sfeature, $sfloc, $nu_sfloc);
    $self->debug("  performed loctransform srcs:%s targets:%s",
                scalar(@sflocs),scalar(@tflocs)) if $verbose;
    return;
}

sub history_log {

}

sub new_feature {
    my $self = shift;
    return
      Data::Stag->unflatten(feature=>[@_]);
}

sub new_featureloc {
    my $self = shift;
    return
      Data::Stag->unflatten(featureloc=>[@_]);
}

our %SPLICEDF =
  (mRNA=>1);
sub is_spliced {
    my $self = shift;
    my $feature = shift;
    my $type = $feature->get_type;
    return $SPLICEDF{$type} || 0;
}

sub iterate {
    my $self = shift;
    my $G = shift;
    my $v = shift;
    my $func = shift;
    my $iterator = $self->iterator($G, $v);
    while (my $next_v = $iterator->next_vertex) {
	$func->($next_v);
    }
}

sub iterator {
    my $self = shift;
    return Iterator->new(@_);
}

sub feature_iterator {
    my $self = shift;
    return Iterator->new($self->graph, @_);
}


=head2 get_features_by_type

 Usage   - my $exons = $cg->get_features_by_type('exon');
 Returns - listref of L<Data::Stag> feature nodes
 Args    - type string

gets features by type (exact - does not traverse ontology graph)

=cut

sub get_features_by_type {
    my $self = shift;
    my $type = shift;
    my $fidx = $self->feature_idx;
    my @fs = grep {$_->get_type eq $type} values %$fidx;
    return [@fs];
}

=head2 get_features

 Usage   - my $features = $cg->get_features;
 Returns - listref of L<Data::Stag> feature nodes
 Args    - none

returns all features

=cut

sub get_features {
    my $self = shift;
    my $fidx = $self->feature_idx;
    return [values %$fidx];
}

sub validate {
    my $self = shift;
    my $W = shift;
    my $G = $self->graph;
    my $fidx = $self->feature_idx;
    my $vertices = $G->vertices;
    $W->start_event('chaos_validation');
    my @missing_fids = ();
    my @errs = ();
    foreach my $v (@$vertices) {
	if (exists $fidx->{$v}) {
	}
	else {
	    $W->event(missing_feature=>$v);
	    push(@missing_fids, $v);
	}
    }
    if (@missing_fids) {
	push(@errs, "Missing feature_ids: @missing_fids");
    }
    my $features = $self->get_features;
    foreach my $f (@$features) {
	my $name = $f->get_name;
	my $res = $f->get_residues;
	my @flocs = $f->get_featureloc;
	if ($res && scalar(@flocs)) {
	    my $implicit_res = $self->derive_residues($f);
	    if ($res ne $implicit_res) {
		$W->event(residues_conflict=>$name);
		push(@errs, "residues $name");
	    }
	}
    }
    $W->end_event('chaos_validation');
    return @errs;
}


=head2 name_all_features

 Usage   - $cg->name_all_features
 Returns -
 Args    -

makes sure all feature have names. will not affect features that
already have names

sets both feature/name and feature/uniquename

=cut

sub name_all_features {
    my $self = shift;
    my $basename = shift;

    my %global_id_by_type = ();   # for unnamed top features

    my $topfs = $self->top_features;
    foreach my $topf (@$topfs) {
	my $childfs = $self->get_all_contained_features($topf);
	
	my $tname = $topf->get_name;
	if (!$tname) {
	    my $type = $topf->get_type;
	    $global_id_by_type{$type} = 0 unless $global_id_by_type{$type};
	    my $id = ++$global_id_by_type{$type};
	    $tname = "$type$id";
	    if ($basename) {
		$tname = "$basename-$tname";
	    }
	    $topf->set_name($tname);
#	    $topf->set_uniquename($tname);
	}
	my %id_by_type = ();      # unique within a topfeature
    
	foreach my $cf (@$childfs) {
	    my $type = $cf->get_type;
	    $id_by_type{$type} = 0 unless $id_by_type{$type};
	    my $id = ++$id_by_type{$type};
	    my $name = "$tname-$type-$id";
	    $cf->set_name($name);
	    $cf->set_uniquename($name);
	}
    }
    return;
}

sub asciitree {
    my $self = shift;
    my $containers = $self->unlocalised_features;
    my $fidx = $self->feature_idx;
    foreach my $f (@$containers) {
	$self->asciifeature($f, 0);
    }
}

sub asciifeature {
    my $self = shift;
    my $f = shift;
    my $indent = shift || 0;

    my @flocs = $f->get_featureloc;
    printf("%s%s %s \"%s\" %s\n",
	   ' '  x $indent,
	   $f->get_type,
	   $f->get_feature_id,
	   $self->get_feature_shortlabel($f->get_feature_id),
	   join(";",
		map {
		    sprintf("%s->%s on %s",
			    $_->get_nbeg, $_->get_nend,
			    $self->get_feature_shortlabel($_->get_srcfeature_id))
		} @flocs),
	  );
    my $cfeats = $self->get_features_contained_by($f);
    foreach my $subf (@$cfeats) {
	$self->asciifeature($subf, $indent+1);
    }
    my $lfeats = $self->get_features_on($f);
    foreach my $subf (@$lfeats) {
	my $parents = $self->get_features_containing($subf);
	next if @$parents; # roots only
	printf("%s[anchors]\n",
	       ' ' x ($indent+1));
	$self->asciifeature($subf, $indent+2);
    }
}

sub get_feature_shortlabel {
    my $self = shift;
    my $fid = shift;
    my $fidx = $self->feature_idx;
    my $f = $fidx->{$fid};
    return '?' unless $f;
    my $name = $f->get_name;
    return $name if $name;
    return $fid;
}

sub debug {
    my $self= shift;
    return unless $self->verbose;
    my $fmt = shift;
    my $t = time;
    my $lt = localtime $t;
    print STDERR "# "; 
    printf STDERR ($fmt, @_);
    print STDERR " [$t] $lt\n";
}


1;

package Iterator;

sub new {
    my $self = shift;
    my $G = shift;    # graph or array of graphs
    my $v = shift;
    my $dir = shift || 'out';
    unless (ref($G) eq 'ARRAY') {
	$G = [$G];
    }

    # if vertices not supplied by user, choose a random one
    if (!$v) {
	($v) = map {@{$_->vertices}} @$G;
    }
    my $depth = 0;

    # nodes to be explored;
    #  each node is an arrayref [$depth,$subj,$obj,$rank]
    my @nodes = ();
    
    my $closure = sub {
	my $meth = shift;
	if ($meth eq 'next_vertex') {
	    my @edges;
	    my @all_child_nodes = ();
	    foreach my $g (@$G) {
		if ($dir eq 'out') {
                    # sink-to-source (root-to-leaf)
		    @edges = $g->edges_to($v);
		}
		else {
                    # source-to-sink (leaf-to-root) DEFAULT
		    @edges = $g->edges_from($v);
		}
		my @child_nodes = ();
		while (my $edge = shift @edges) {
		    my ($subj,$obj) = @$edge;
		    my $rank = $g->get_edge_attribute($subj,$obj,'rank');
		    die("Assertion error") unless defined $rank;
		    push(@child_nodes, [$depth+1, $subj, $obj, $rank]);
		}
		@child_nodes = sort { $a->[3] <=> $b->[3] } @child_nodes;
                # default: depth-first
		push(@all_child_nodes, @child_nodes);
	    }
	    push(@nodes, @all_child_nodes);
	    my $nextnode = shift @nodes;
	    if (!$nextnode) {
		$depth = -1;
		return;
	    }
	    $depth = $nextnode->[0];
            # out: use subj
            # in:  use obj
	    $v = $dir eq 'out' ? $nextnode->[1] : $nextnode->[2];
	    return $v;
	}
	elsif ($meth eq 'depth') {
	    return $depth;
	}
	else {
	    $self->freak("cannot call method \"$meth\" on an iterator");
	}
    };
    bless $closure, 'Iterator';
    return $closure;
}

sub next_vertex { &{shift @_}('next_vertex')}
sub depth { &{shift @_}('depth')}


1;

