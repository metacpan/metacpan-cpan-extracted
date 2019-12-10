my $max_id = int( log( 2_000_000_000 ) / log( 2 ));
my $max_size = 2 ** $max_id;
my $big = 2 ** 31;
print STDERR "Max ($big) id $max_id, $max_size\n";

for my $id ( 12..30 ) {
    my $size = 2 ** $id;
    print " $id --> $size\n";
    # check below and above
    my $calc_id = int( log( $size ) / log( 2 ));
    if( $calc_id != $id ) {
        print " EXACT ** $id vs calc'd $calc_id --> $size **\n";
    }
    
    $size--;
    my $calc_id = int( log( $size ) / log( 2 ));
    if( $calc_id != ($id-1) ) {
        print "THE UNDER ** $id vs calc'd $calc_id --> $size **\n";
    }

    $size += 2;
    my $calc_id = int( log( $size + 1 ) / log( 2 ));
    if( $calc_id != (1+$id) ) {
        print "THE OVER ** ".(1+$id)." vs calc'd $calc_id --> $size **\n";
    }
}

for my $rec_size ( 4096 .. $max_size ) {
    my $id = int( log( $rec_size ) / log( 2 ));
    my $size = 2 ** $id;
    print " *** $rec_size ($id/$size)*** \n";
    exit;
}
