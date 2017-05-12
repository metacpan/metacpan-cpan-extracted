use lib '..';
use BTRIEVE::SAVE;

# Btrieve handles its indices well, but sometimes the indices should
# be defined outside the typical c programmers budget. Let's make an
# index that allows sort by location and title.

open F, $ARGV[0];
$/="";
while (<F>) {
    my $rhfixed;
    my ($fixed,$var)= split(/\n/);
    my @fvals = split(/\t/,$fixed);
    print $fvals[-1]." ";
    for (qw/loc dbcn date ZZ/) {
	$rhfixed->{$_}= shift @fvals;
    }

    $rhfixed->{loc_title_sort}= "a"x7;
    my $rnull = \'';
    push @ans,[$rhfixed,$rnull,\$var]; 
}

# OK, perl can sort easily in weird fashions so lets 
# do it in perl and record the results for other folk.

my @sort_ans = sort by_location_title @ans;

# now we have a bunch of references in sorted order, we can 
# fill the appropriate field  up with a generated key.

my $sort_key = "a"x 7; 
# Using integers ($sort_key = 0) is more efficient.
# But for illustrative purposes I prefer strings.

for (@sort_ans) {
       $_->[0]{loc_title_sort}=$sort_key; 
       $sort_key++;
}

my $btr_rec = BTRIEVE::SAVE::REC->newconfig('loctitle.std');

for (@ans) {
     $btr_rec->{values}=$_;
     print $btr_rec->counted_rec_hash();
}
print "\cZ";

# Now we have a save file with a generated key in the 'loc_title_sort'
# position.  Run butil -load on this and Btrieve can now sort by a
# combination of fixed and variable key!

#-------------- sort subroutine --------------

sub by_location_title {
    $a->[0]{location} cmp $b->[0]{location} ||
	${$a->[2]} cmp ${$b->[2]}
}
