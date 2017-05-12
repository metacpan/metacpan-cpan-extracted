#!/usr/bin/perl
use strict;
use warnings;
use Data::RefQueue;

# ###
# These are the id's we need to fetch, and this is the
# order we want to return.
my $refq = new RefQueue (32, 123, 39, 20, 33, 123);

# ### get id's we already have in cache.
foreach my $obj_id (@{$refq->not_filled}) {
    my $objref = get_obj_from_cache($obj_id);
    if($objref) {
        $refq->save($objref)
    }
    else {
        $refq->next;
    }
} 
$refq->reset;

# ### fetch the rest from the database. 
my $query = build_select_query(@{$refq->not_fille});
$db->query($query);
while(my $result = $db->fetchrow_hash) {
    my $objref = build_obj_from_db_result($result);
    $refq->insert_at($objref->id, $objref);
}
# ### remove the id's we didn't find.
$refq->cleanse;
                                                                                                           
my $final_objects = $refq->queue;                                                                        
