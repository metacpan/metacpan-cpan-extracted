
BEGIN {
    my @options = (
        '+ignore' => 'Data/Dumper',
        '+select' => 'DBIx::PreQL',
    );
    require Devel::Cover
        &&  Devel::Cover->import( @options )
        if  $ENV{COVER};
}

use strict;
use warnings;
use Data::Dumper;

use Test::More;

use_ok( 'DBIx::PreQL' );


done_testing();
