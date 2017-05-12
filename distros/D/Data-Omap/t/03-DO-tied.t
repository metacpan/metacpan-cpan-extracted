use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

my( $omap, %omap, @keys, @values, $bool, $key, $value, @a );

Data::Omap->order( '' );  # ordering is class-level, turn off for now

$omap = tie %omap, 'Data::Omap';

is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "empty tied object" );

# empty %omap

@keys = keys %omap;  # via FIRSTKEY/NEXTKEY
is( "@keys", "",
    "keys %hash on empty object" );

@values = values %omap;  # via FIRSTKEY/NEXTKEY
is( "@values", "",
    "values %hash on empty object" );

$bool = %omap;   # SCALAR
is( $bool, undef,
    "scalar %hash on empty object" );

$bool = exists $omap{ a };  # EXISTS
is( $bool, '',
    "exists hash{key} on empty object" );

$value = $omap{ a };  # FETCH
is( $value, undef,
    "hash{key} (FETCH) on empty object" );

delete $omap{ a };  # DELETE
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "delete hash{key} on empty object" );

%omap = ();  # CLEAR
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "%hash = () to clear empty object" );

# non-empty %omap

$omap{ z } = 26;  # STORE
$omap{ y } = 25;
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25}], 'Data::Omap' )",
    "hash{key}=value" );

$bool = exists $omap{ z };
is( $bool, 1,
    "exists hash{key}" );

$value = $omap{ z };
is( $value, 26,
    "value=hash{key}" );

@values = @omap{ 'y', 'z' };
is( "@values", "25 26",
    "values=\@hash{key,key} (get slice)" );

@omap{ 'y', 'z' } = ( "Why", "Zee" );
is( Dumper($omap), "bless( [{'z' => 'Zee'},{'y' => 'Why'}], 'Data::Omap' )",
    "\@hash{key,key}=values (set slice)" );

delete $omap{ z };
is( Dumper($omap), "bless( [{'y' => 'Why'}], 'Data::Omap' )",
    "delete hash{key}" );

@omap{ 'a', 'b', 'c' } = ( 1, 2, 3 );
@keys = keys %omap;
is( "@keys", "y a b c",
    "keys %hash" );

@values = values %omap;
is( "@values", "Why 1 2 3",
    "values %hash" );

while( ( $key, $value ) = each %omap ) {
    push @a, "$key $value";
}
is( "@a", "y Why a 1 b 2 c 3",
    "each %hash" ); 

$bool = %omap;
is( $bool, 4,
    "scalar %hash" );

%omap = ();  # CLEAR
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "%hash = () to clear hash" );

my $warning;
local $SIG{ __WARN__ } = sub{ ($warning) = @_ };
untie %omap;
like( $warning, qr/untie attempted while 1 inner references still exist/,
    "expected untie warning (object still in scope)" );
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "(empty) object is still visible" );

