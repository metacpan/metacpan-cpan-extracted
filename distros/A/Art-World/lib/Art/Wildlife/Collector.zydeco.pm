class Collector with Buyer {
    has money! ( type => Num );
    # Actually an ArrayRef of Artworks
    has collection (
        type    => ArrayRef[Any, 0, 100],
        default => sub { [] } ) ;
}
