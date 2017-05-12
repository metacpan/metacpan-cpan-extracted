# $Id$
#
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
#
# The goal is always update by freshening the annotation bundle and
# the features. This is achieved by removing all existing features and
# annotations for a found entry.
# The idea behind this is to discard all existing annotation in order to
# have the update reflect all changes in a datasource. This would
# apply to datasources that do not assign a version nor a data, like
# UniGene or LocusLink.
#
sub {
    my ($old,$new,$db) = @_;

    # as a special tuning step we make sure here that caching is turned
    # on for Annotation::Reference objects, since the updated record will
    # in many cases have almost the same references as were already there
    my $refadp = $db->get_object_adaptor("Bio::Annotation::Reference");
    $refadp->caching_mode(1) if $refadp && (! $refadp->caching_mode);

    # remove existing features
    if($old->isa("Bio::FeatureHolderI")) {
	foreach my $fea ($old->get_all_SeqFeatures()) {
	    $fea->remove();
	}
    }
    # remove existing annotation
    if($old->isa("Bio::AnnotatableI")) {
	my $anncoll = $old->annotation();
	if($anncoll->isa("Bio::DB::PersistentObjectI")) {
	    $anncoll->remove(-fkobjs => [$old]);
	}
    }
    # remove cluster members if this is a cluster
    if($old->isa("Bio::ClusterI")) {
	$old->adaptor->remove_members($old);
    }

    return $new;
}
