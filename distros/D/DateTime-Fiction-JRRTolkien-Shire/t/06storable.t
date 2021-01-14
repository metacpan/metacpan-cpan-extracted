use strict;
use warnings;

use charnames qw{ :full };

use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;
use Date::Tolkien::Shire::Data;
use Test::More;

eval {
    require Storable;
    1;
} or plan skip_all => q<Module 'Storable' not available>;

plan( tests => 8 );

my $fall = do {
    ( my $dtsd_version = Date::Tolkien::Shire::Data->VERSION() ) =~ s/ _ //smx;
    $dtsd_version ge '0.00601' ? 'fall' : 'the fall';
};

my $u_circ	= "\N{LATIN SMALL LETTER U WITH CIRCUMFLEX}";

my $shire;

$shire = DateTime::Fiction::JRRTolkien::Shire->new(
    year	=> 7463,
    month	=> 1,
    day		=> 8,
);

is( Storable::dclone( $shire )->on_date, <<'EOD' );
Sunday 8 Afteryule 7463

The Company of the Ring reaches Hollin, 1419.
EOD

is( $shire->clone()->on_date, <<'EOD' );
Sunday 8 Afteryule 7463

The Company of the Ring reaches Hollin, 1419.
EOD

$shire = DateTime::Fiction::JRRTolkien::Shire->new(
    year	=> 1419,
    month	=> 1,
    day		=> 15,
);

is( Storable::dclone( $shire )->on_date, <<"EOD" );
Sunday 15 Afteryule 1419

The Bridge of Khazad-dum, and $fall of Gandalf, 1419.
EOD

is( $shire->clone()->on_date, <<"EOD" );
Sunday 15 Afteryule 1419

The Bridge of Khazad-dum, and $fall of Gandalf, 1419.
EOD

$shire = DateTime::Fiction::JRRTolkien::Shire->new(
    year	=> 1419,
    month	=> 1,
    day		=> 15,
    traditional	=> 1,
);

is( Storable::dclone( $shire )->on_date, <<"EOD" );
Sunnendei 15 Afteryule 1419

The Bridge of Khazad-dum, and $fall of Gandalf, 1419.
EOD

is( $shire->clone()->on_date, <<"EOD" );
Sunnendei 15 Afteryule 1419

The Bridge of Khazad-dum, and $fall of Gandalf, 1419.
EOD

$shire = DateTime::Fiction::JRRTolkien::Shire->new(
    year	=> 1419,
    month	=> 1,
    day		=> 15,
    accented	=> 1,
);

is( Storable::dclone( $shire )->on_date, <<"EOD" );
Sunday 15 Afteryule 1419

The Bridge of Khazad-d${u_circ}m, and $fall of Gandalf, 1419.
EOD

is( $shire->clone()->on_date, <<"EOD" );
Sunday 15 Afteryule 1419

The Bridge of Khazad-d${u_circ}m, and $fall of Gandalf, 1419.
EOD
