#! perl

use Test::DescribeMe qw(smoke);
use Test2::V0;

# it's possible that the xpa library already exists, so config.log won't be found.
if ( open my $fh, '<', 'config.log' ) {
    diag( do { local $/; <$fh> } );
    pass( 'output config.log' );
}
else {
    pass( 'config.log not found' );
}
done_testing;
