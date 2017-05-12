# $Id$
#
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
#
# The idea is to trigger an update only if something has changed from
# the old entry to the new one. This closure is tailored towards
# entries from sources that don't assign and increment version
# numbers, but instead annotate release dates. Swissprot and Trembl
# are examples for this. A typical part of Swissprot annotation looks
# like the following lines:
# DT   01-NOV-1995 (Rel. 32, Created)
# DT   01-OCT-1996 (Rel. 34, Last sequence update)
# DT   28-FEB-2003 (Rel. 41, Last annotation update)
# There is two things we can hook ourselves up to, namely the release
# number and the release date. We try to compare the most recent
# dates of the new and the old entry and assume the database entry is
# up-to-date and skip the new entry if the old entry has a date
# identical or later than the new one.
# Also, if the latest date is in the future (this may happen with
# Swissprot), we always update the entry in order not to miss any
# cumulative updates until release.
#
# We use Date::Parse for parsing the date string, so you will need to
# install that before you can use this piece of code.
sub {
    my ($old,$new,$db) = @_;

    # if they're not both Bio::Seq::RichSeqI then there are no dates -
    # and hence we can't do anything here
    if(!($old->isa("Bio::Seq::RichSeqI") && $new->isa("Bio::Seq::RichSeqI"))) {
	warn "Either ".ref($old->obj)." or ".ref($new->obj).
	    " or both are not RichSeqI - cannot compare dates\n";
	return $new;
    }

    # bring in Date::Parse if it hasn't been done yet
    use Date::Parse;

    # as a special tuning step we make sure here that caching is turned
    # on for Annotation::Reference objects, since the updated record will
    # in many cases have almost the same references as were already there
    my $refadp = $db->get_object_adaptor("Bio::Annotation::Reference");
    $refadp->caching_mode(1) if $refadp && (! $refadp->caching_mode);

    my @olddates = sort { str2time($a) <=> str2time($b) } $old->get_dates();
    my @newdates = sort { str2time($a) <=> str2time($b) } $new->get_dates();

    # compare the last (most recent) dates, and compare against today
    my $time = time();
    # convert the date strings to time values
    my $oldtime = (@olddates == 0) ? 0 : str2time($olddates[-1]);
    my $newtime = (@newdates == 0) ? 0 : str2time($newdates[-1]);
    # now compare
    if(($oldtime < $newtime)
       || (($oldtime == $newtime) 
           && (($oldtime == 0) || ($oldtime >= $time)))) {
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
	print STDERR
	    "about to update ",$new->object_id()," (updated on ",
	    (@olddates ? $olddates[-1] : "<undef>"),
	    " -> ",
	    (@newdates ? $newdates[-1] : "<undef>"),
	    ")\n";
    } else {
	# skip the update
	$new = undef;
    }
    return $new;
}
