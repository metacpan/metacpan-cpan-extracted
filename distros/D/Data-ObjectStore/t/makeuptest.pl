use Data::ObjectStore;

my $dir = "t/OLDVERSIONDB";
`rm -rf $dir`;

sub start {
    my $store = Data::ObjectStore::open_store( $dir );
    my $root = $store->load_root_container;

    my $h = {SOME => "HVAL"};
    my $l = [$h,"AVAL"];
    my $o = $store->create_container( {
        list => $l,
        hash => $h,
        scala => "VALUE",
				      } );
    $o->set_self( $o );
    $h->{foo} = $o;
    $h->{bar} = $h;
    push @$l, $l, $h;

    $root->set_list( $l );
    $store->save;

    $store->[0][1]->_ensure_entry_count( 6 );
    
    my $delo = $store->create_container( { delme => "now" } );
    $root->set_delo( $delo );
    $store->save;

    my $finky = $store->create_container( { delme => "also" } );

    $root->set_delo( undef );

    $store->save;
}
start();
my $store = Data::ObjectStore::open_store( $dir );
for my $idx ( 1..$store->[0]->entry_count ) {
  my $x = $store->_fetch( $idx );
  print STDERR Data::Dumper->Dump(["WEEE ($x) $idx"]);
}
