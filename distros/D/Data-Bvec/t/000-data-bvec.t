use Test::More tests => 6;

use Data::Bvec qw( :all );

POD1: {
         use Data::Bvec;

         my $bv = Data::Bvec::->new( nums=>[1,2,3] );

         my $vec  = $bv->get_bvec();  # 01110000
         my $bstr = $bv->get_bstr();  # '-134'
         my $nums = $bv->get_nums();  # [1,2,3]

is( bit2str( $vec ),     '01110000', 'get_bvec()' );
is( uncompress( $bstr ), '01110000', 'get_bstr()' );
is( "@$nums",            '1 2 3',    'get_nums()' );

}

POD2: {
         use Data::Bvec qw( :all );

         my $vec  = num2bit( [1,2,3] );                # 0111000
         set_bit( $vec, 4, 1 );                        # 0111100
         my $bstr = compress bit2str $vec;             # '-143'
         my $nums = bit2num str2bit uncompress $bstr;  # [1,2,3,4]

is( bit2str( $vec ),     '01111000', 'get_bvec()' );
is( uncompress( $bstr ), '01111000', 'get_bstr()' );
is( "@$nums",            '1 2 3 4',  'get_nums()' );

}

