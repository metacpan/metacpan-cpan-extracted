use strict;

use Test::More;

use File::Spec::Functions qw< catfile >;
use Business::IS::PIN qw< :all >;

unless ( open my $fh, '<', catfile qw< t data > ) {
    plan skip_all => 'optional test data not found';
} else {
    plan qw< no_plan >;
    while (<$fh>) {
        chomp;
        ok( valid( $_ ) );
    }
}









