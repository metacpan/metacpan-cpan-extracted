use Test::More;

use Data::Bvec qw( :all );

    #                   0----+----1----+----2----+----3-
    my $tstr =         '01110011110001111100001111110001';
    my $vec  = str2bit '01110011110001111100001111110001';

POD_bvec: {

    my $bv  = Data::Bvec::->new( bvec => $vec );

is( bit2str( $bv->get_bvec ), $tstr, 'new() POD_bvec' );

}

POD_bstr: {

    my $bstr = compress bit2str $vec;
    my $bv   = Data::Bvec::->new( bstr => $bstr );

is( $bv->get_bstr, '-1324354631', 'new() POD_bstr' );

}

POD_nums: {

    my $nums = bit2num $vec;
    my $bv   = Data::Bvec::->new( nums => $nums );

my @nums = $bv->get_nums;
is( "@nums", '1 2 3 6 7 8 9 13 14 15 16 17 22 23 24 25 26 27 31', 'new() POD_nums' );

}

POD_bvec2nums: {

    my $bv = Data::Bvec::->new( bvec2nums => $vec );

my @nums = $bv->get_nums;
is( "@nums", '1 2 3 6 7 8 9 13 14 15 16 17 22 23 24 25 26 27 31', 'new() POD_bvec2nums' );

}

POD_nums2bvec: {

my $nums = bit2num $vec;

    my $bv = Data::Bvec::->new( nums2bvec => $nums );

is( bit2str( $bv->get_bvec ), $tstr, 'new() POD_nums2bvec' );

}

POD_bvec2bstr: {

    my $bv = Data::Bvec::->new( bvec2bstr => $vec );

is( $bv->get_bstr, '-1324354631', 'new() POD_bvec2bstr' );

}

POD_bstr2bvec: {

my $bstr = compress bit2str $vec;

    my $bv = Data::Bvec::->new( bstr2bvec => $bstr );

is( bit2str( $bv->get_bvec ), $tstr, 'new() POD_bstr2bvec' );

}

POD_bstr2nums: {

my $bstr = compress bit2str $vec;

    my $bv = Data::Bvec::->new( bstr2nums => $bstr );

my @nums = $bv->get_nums;
is( "@nums", '1 2 3 6 7 8 9 13 14 15 16 17 22 23 24 25 26 27 31', 'new() POD_bstr2nums' );

}

POD_nums2bstr: {

my $nums = bit2num $vec;

    my $bv = Data::Bvec::->new( nums2bstr => $nums );

is( $bv->get_bstr, '-1324354631', 'new() POD_nums2bstr' );

}

use Test::More tests => 9;

__END__
