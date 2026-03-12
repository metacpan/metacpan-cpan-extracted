use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
package Archive::CAR v0.0.4 {
    use Archive::CAR::v1;
    use Archive::CAR::v2;

    sub from_file ( $class, $filename ) {
        open( my $fh, '<:raw', $filename ) or die "Can't open $filename: $!";
        my $first_bytes;
        read( $fh, $first_bytes, 11 );
        seek( $fh, 0, 0 );
        return Archive::CAR::v2->new()->read($fh)
            if $first_bytes eq pack( 'H*', '0aa16776657273696f6e02' ) || $first_bytes eq pack( 'H*', '0aa26576657273696f6e02' );
        return Archive::CAR::v1->new()->read($fh);
    }

    sub write ( $class, $filename, $roots, $blocks, $version = 1 ) {
        open( my $fh, '>:raw', $filename ) or die "Can't open $filename for writing: $!";
        my $car_obj = $version == 2 ? Archive::CAR::v2->new() : Archive::CAR::v1->new();
        $car_obj->write( $fh, $roots, $blocks );
        close($fh);
    }
};
#
1;
