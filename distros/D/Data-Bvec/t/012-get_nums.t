use Test::More;

use Data::Bvec qw( bit2str );

POD: {

my $bv = Data::Bvec::->new( nums => [1,2,3] );

    my @integers = $bv->get_nums();  # list returned in list context
    my $ints     = $bv->get_nums();  # aref returned in scalar context

is( "@integers", '1 2 3', 'get_nums() list POD' );
is( "@$ints",    '1 2 3', 'get_nums() aref POD' );

}

use Test::More tests => 2;

__END__
