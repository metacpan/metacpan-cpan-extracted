# $Id$
#
# BioPerl module for Bio::DB::BioSQL::PathAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioSQL::PathAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Bio::Ontology::PathI DB adaptor 

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bio.perl.org

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bioperl.org
  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::PathAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble 

use Bio::DB::BioSQL::RelationshipAdaptor;
use Bio::DB::PersistentObjectI;
use Bio::Ontology::Path;

@ISA = qw(Bio::DB::BioSQL::RelationshipAdaptor);

# new is inherited

=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its respective
           entity in the datastore.

           Slots should be methods callable without an argument.

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ($self->SUPER::get_persistent_slots(@args), "distance");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_persistent_slot_values {
    my ($self,$obj,$fkobjs) = @_;
    my @vals = (@{$self->SUPER::get_persistent_slot_values($obj,$fkobjs)},
		$obj->distance());
    return \@vals;
}

=head2 instantiate_from_row

 Title   : instantiate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

           This implementation call populate_from_row() to do the real job.

           We override this here in order to create a
           Bio::Ontology::Path object by default.

 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : A reference to an array of column values. The first column
           is the primary key, the other columns are expected to be in
           the order returned by get_persistent_slots().

           Optionally, the object factory to be used for instantiating
           the proper class. The adaptor must be able to instantiate a
           default class if this value is undef.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if($fact) {
	    $obj = $fact->create_object();
	} else {
	    $obj = Bio::Ontology::Path->new();
	}
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : The object to be populated.
           A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,$obj,$row) = @_;

    $obj = $self->SUPER::populate_from_row($obj, $row);
    if($obj && $row && @$row) {
	$obj->distance($row->[1]) if defined($row->[1]);
    }
    return $obj;
}

=head1 Methods specific to this adaptor

=cut

=head2 compute_transitive_closure

 Title   : compute_transitive_closure
 Usage   :
 Function: Compute the transitive closure over a given ontology
           and populate the respective path table in the relational
           schema.

           There are options that allow one to create certain
           necessary relationships between predicates on-the-fly. Read
           below.

 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The ontology over which to create the transitive closure
           (a Bio::Ontology::OntologyI compliant object).

           In addition, named parameters. Currently, the following are
           recognized.

             -truncate   If assigned a true value, will cause an existing
                         transitive closure for the ontology be deleted
                         from the path table. Usually, this option should
                         be enabled.

             -predicate_superclass A Bio::Ontology::TermI compliant object
                         that specifies a common ancestor predicate
                         for all predicates in the ontology. If this
                         is specified, the method will create and
                         serialize relationships between all
                         predicates in the ontology and the ancestor
                         predicate, where the ancestor predicate is
                         the object, the predicate is either the one
                         given by -subclass_predicate or the term
                         'implies', and the ontology is the
                         ontology referenced by the ancestor
                         predicate.

                         If this is not provided, the aforementioned
                         relationships should be present in an
                         ontology in the database already, unless the
                         ontology over which to compute the transitive
                         closure has only one predicate, or if paths
                         over mixed predicates are void. Otherwise the
                         transitive closure will not be complete for
                         mixed predicate paths.

             -subclass_predicate A Bio::Ontology::TermI compliant object
                         that represents the predicate for the
                         relationship between predicate A and
                         predicate B if predicate A can be considered
                         to subclass, or imply, predicate B.

             -identity_predicate A Bio::Ontology::TermI compliant object
                         that represents the predicate for the
                         identity of a predicate with itself. If
                         provided, the method will create
                         relationships for all predicates in the
                         ontology, where subject and object are the
                         predicate of the ontology, the predicate is
                         the supplied identity predicate, and the
                         ontology is the ontology referenced by the
                         supplied term object.

                         If this is not provided, the aforementioned
                         relationships should be present in an
                         ontology in the database already. Otherwise the
                         transitive closure will be incomplete.

                         The predicate will also be used for
                         indicating identity between a term and itself
                         for the paths of distance zero between a term
                         and itself. If undef the zero distance paths
                         will not be created.


=cut

sub compute_transitive_closure{
    my ($self,$ont,@args) = @_;

    # check whether we need to create predicate relationships on the fly
    my ($trunc, $ancestor_pred, $subclass_pred, $identity_pred) =
	$self->_rearrange([qw(TRUNCATE
			      PREDICATE_SUPERCLASS
			      SUBCLASS_PREDICATE
			      IDENTITY_PREDICATE
			      )],
			  @args);
    # need to create identity relationships?
    if (defined($identity_pred)) {
	# set up the relationship object we'll reuse
	my $rel = Bio::Ontology::Relationship->new(
				   -ontology => $identity_pred->ontology());
	$rel = $self->db->create_persistent($rel);
	# set the constant(s) (only one here)
	$rel->predicate_term($identity_pred);
	# create an identity rel.ship for each predicate
	my @preds = $ont->get_predicate_terms();
	# if there is a superclass predicate, we need to create an identity
	# relationship for that, too
	push(@preds, $ancestor_pred) if $ancestor_pred;
	# now loop over the list of predicates
	foreach my $pred (@preds) {
	    $rel->primary_key(undef);
	    $rel->subject_term($pred);
	    $rel->object_term($pred);
	    $rel->create();
	}
    }
    # need to create subclass relationships?
    if (defined($ancestor_pred)) {
	# set up the relationship object we'll reuse
	my $rel = Bio::Ontology::Relationship->new(
				   -ontology => $ancestor_pred->ontology());
	$rel = $self->db->create_persistent($rel);
	# create a subclasses predicate if none supplied
	$subclass_pred = Bio::Ontology::Term->new(
                                   -name     => "subclasses",
				   -ontology => $ancestor_pred->ontology())
	    unless $subclass_pred;
	# and make it persistent if it isn't already
	$subclass_pred = $self->db->create_persistent($subclass_pred)
	    unless $subclass_pred->isa("Bio::DB::PersistentObjectI");
	# set the constants
	$rel->object_term($ancestor_pred);
	$rel->predicate_term($subclass_pred);
	# create one subclass rel.ship for each predicate
	foreach my $pred ($ont->get_predicate_terms()) {
	    $rel->primary_key(undef);
	    $rel->subject_term($pred);
	    $rel->create();
	}
    }
    # make sure the ontology object is a persistent object
    $ont = $self->db->create_persistent($ont)
	unless $ont->isa("Bio::DB::PeristentObjectI");
    # now delegate to the driver
    return $self->dbd->compute_transitive_closure($self,
                                                  $ont,
                                                  $identity_pred,
                                                  $trunc);
}

1;
