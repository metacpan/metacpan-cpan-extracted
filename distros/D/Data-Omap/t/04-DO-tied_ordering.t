use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

my( $omap, %omap, @keys, @values, $bool, $key, $value, @a );

$omap = tie %omap, 'Data::Omap';

Data::Omap->order( 'sa' );  # string ascending

$omap{ z } = 26;
$omap{ y } = 25;
$omap{ x } = 24;
is( Dumper($omap), "bless( [{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

$omap{ a } = 1;
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

Data::Omap->order( '' );  # turn ordering off

$omap{ b } = 2;
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}], 'Data::Omap' )",
    "hash{key}=value, no ordering" );

%omap = ();
Data::Omap->order( 'sa' );  # string ascending turned on again

$omap{ 100 } = 'hundred';
$omap{ 10  } = 'ten';
$omap{ 2   } = 'two';
is( Dumper($omap), "bless( [{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

%omap = ();
Data::Omap->order( 'na' );  # number ascending

$omap{ 100 } = 'hundred';
$omap{ 10  } = 'ten';
$omap{ 2   } = 'two';
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'na'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'na'" );

%omap = ();
Data::Omap->order( 'sd' );  # string descending

$omap{ x } = 24;
$omap{ y } = 25;
$omap{ z } = 26;
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

$omap{ a } = 1;
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

%omap = ();

$omap{ 2   } = 'two';  # order still 'sd'
$omap{ 10  } = 'ten';
$omap{ 100 } = 'hundred';
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

%omap = ();
Data::Omap->order( 'nd' );  # number descending

$omap{ 2   } = 'two';
$omap{ 10  } = 'ten';
$omap{ 100 } = 'hundred';
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'nd'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'nd'" );

%omap = ();
Data::Omap->order( 'sna' );  # string/number ascending
$omap{ z } = 26;
$omap{ y } = 25;
$omap{ x } = 24;  # set and add are the same for new key/value members
$omap{ 100 } = 'hundred';
$omap{ 10  } = 'ten';
$omap{ 2   } = 'two';
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sna'" );

%omap = ();
Data::Omap->order( 'snd' );  # string/number descending
$omap{ x } = 24;  # set and add are the same for new key/value members
$omap{ y } = 25;
$omap{ z } = 26;
$omap{ 2   } = 'two';
$omap{ 10  } = 'ten';
$omap{ 100 } = 'hundred';
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'snd'" );

%omap = ();
Data::Omap->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
$omap{ 550 } = "note";
$omap{ 500 } = "note";
$omap{ 510 } = "note";
$omap{ 650 } = "subj";
$omap{ 600 } = "subj";
$omap{ 610 } = "subj";
$omap{ 245 } = "title";
$omap{ 100 } = "author";
is( Dumper($omap), "bless( [{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}], 'Data::Omap' )",
    "hash{key}=value, custom ordering" );

