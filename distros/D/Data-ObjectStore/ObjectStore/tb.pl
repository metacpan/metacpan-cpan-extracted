use Data::ObjectStore;

use Data::Dumper;

use strict;

my $dir = 't/OLDVERSIONDB';
my $store = Data::ObjectStore::open_store( $dir );

my $root = $store->load_root_container;

if( 1 ) {

    my $h = {};
    my $l = [$h];
    my $o = $store->create_container( {
        list => $l,
        hash => $h,
                                      } );
    $o->set_self( $o );
    $h->{foo} = $o;
    $h->{bar} = $h;
    push @$l, $l, $h;

    $root->set_list( $l );

    my $o2 = $store->create_container( { delme => 'now' } );
    
    $store->save;
}
print STDERR Data::Dumper->Dump([$root->get_list,"LL"]);

