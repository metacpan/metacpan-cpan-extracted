# $Id$
#
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
#
# This scriptlet will remove all annotation and features associated
# with the old entry using direct SQL queries. It is therefore specific
# to the schema; in fact it is presently specific to the Oracle version
# of the biosql schema. However, it is easily adapted to the mysql/Pg
# versions by adapting the primary key/foreign key names.
#
# The reason to issue direct SQL queries is purely efficiency when
# updating the data content.
#
# Other than that, the way of removing annotation association for a
# found entry is identical to the idea behind freshen-annot.pl.
#
sub {
    my ($old,$new,$db) = @_;

    # the found object is a persistent object, so we have access to
    # its adaptor for caching statements and getting the database handle
    my $adp = $old->adaptor();

    # remove cluster members if this is a cluster - this is not dependent 
    # on the members having actually been loaded, so is compatible with
    # --flatlookup mode
    if($old->isa("Bio::ClusterI")) {
        $adp->remove_members($old);
    }

    # the tables where we delete by simple foreign key matching
    my @del_by_fk_tables = ("bioentry_qualifier_value",
                            "anncomment",
                            "bioentry_reference",
                            "bioentry_dbxref");
    # add seqfeature only if the entry is a feature holder
    push(@del_by_fk_tables, "seqfeature") if $new->isa("Bio::FeatureHolderI");

    # delete for each table by foreign key
    foreach my $tbl (@del_by_fk_tables) {
        # build the sql statement
        my $sql = "DELETE FROM $tbl WHERE ent_oid = ?";
        if ($tbl eq "bioentry_qualifier_value") {
            # if the new entry comes with type already attached, then we
            # need to delete the old one but otherwise add a constraint that
            # preserves the old type (as its really unlikely to change)
            my ($bioentrytype) = 
                $new->isa("Bio::AnnotatableI")
                ? $new->annotation->get_Annotations("Bioentry Type Ontology")
                : (undef);
            if (!$bioentrytype) {
                $sql .= " AND trm_oid NOT IN "
                    . "(SELECT t.Oid FROM Term t, Ontology o "
                    . "WHERE t.Ont_Oid = o.Oid "
                    . "AND o.name = 'Bioentry Type Ontology')";
            }
        }
        # we use DBI's facility for statement caching here
        my $sth = $adp->dbh->prepare_cached($sql);
        # and execute with the primary key
        if (! $sth->execute($old->primary_key())) {
            $old->warn("failed to execute sql statement ($sql): "
                       . $sth->errstr);
            $sth->finish();
        }
    }
    # done
    return $new;
}
