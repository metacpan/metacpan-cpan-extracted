# $Id$
#
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
#
# The goal is to retain existing features and annotation, avoid updates of
# those, but add from the new object all features and annotation that wasn't
# yet on the database object.
#
sub {
    my ($old,$new,$db) = @_;

    # merge annotation objects
    if($old->isa("Bio::AnnotatableI")) {
	# remove the old ones from the object (this doesn't remove them
	# from the database, nor does it remove the associations)
        my $oanncoll = $old->annotation();
        my %annkeys = map { ($_,1); } (
            $oanncoll->get_all_annotation_keys(),
            $new->annotation->get_all_annotation_keys()
        );
        foreach my $annkey (keys(%annkeys)) {
            my @anns = $oanncoll->remove_Annotations($annkey);
            my %annmap = ();
            my $r = 0;
            foreach (@anns) { 
                $r = $_->rank if $_->rank > $r;
                $annmap{$_->as_text()} = 1;
            }
            foreach my $ann ($new->annotation->get_Annotations($annkey)) {
                # only add on those that weren't there yet (i.e., don't
                # update annotations, just add new ones)
                next if exists($annmap{$ann->as_text});
		$ann = $db->create_persistent($ann);
		$ann->rank(++$r);
		$oanncoll->add_Annotation($ann);
	    }
	}
    }
    # merge features
    if($old->isa("Bio::SeqI")) {
	# same story here: remove existing ones from the object as we
	# don't want them updated (removing from the object does not
	# delete from the database)
	my @feas = $old->flush_SeqFeatures();
	my $r = 1;
	foreach (@feas) { $r = $_->rank if $_->rank > $r; }
	foreach my $fea ($new->top_SeqFeatures()) {
	    # add on those with not yet seen location, primary_tag or
	    # source_tag
	    if(! grep { 
		$_->location->equals($fea->location) &&
		    ($_->primary_tag eq $fea->primary_tag) &&
		    ($_->source_tag eq $fea->source_tag); } @feas) {
		$fea = $db->create_persistent($fea);
		$fea->rank(++$r);
		$old->add_SeqFeature($fea);
	    }
	}
    }
    return $old;
}
