package My::Test::common;

use Test2::V0;

use Exporter 'import';

our @simplebin_cols = qw/ rt_x rt_y rt_z rt_kev /;

our @EXPORT = qw( @simplebin_cols chk_simplebin_piddles );

sub chk_simplebin_piddles {
    my ( $msg, @pdls ) = @_;

    my $ctx = context;

    my $idx = 0;
    foreach my $pdl ( @pdls ) {
        my $name = $simplebin_cols[ $idx++ ];

        is( [ $pdl->dims ], [20], "$msg: $name dims" );
        ok( ( $pdl == PDL->sequence( 20 ) * $idx )->all, "$msg: $name values" );
    }

    $ctx->release;
    return 1;
}


1;
