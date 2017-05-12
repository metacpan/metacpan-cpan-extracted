use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;
use DBICTest::Constants qw/ COUNT_ARTIST COUNT_CD COUNT_TRACK /;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 6 );
}

my $schema = DBICTest->init_schema;

## master
my $itr_m_artist = $schema->resultset('Artist')->search;
is($itr_m_artist->count,COUNT_ARTIST,'master artist "count"');

my $itr_m_cd = $schema->resultset('CD')->search;
is($itr_m_cd->count,COUNT_CD,'master cd "count"');

my $itr_m_track = $schema->resultset('Track')->search;
is($itr_m_track->count,COUNT_TRACK,'master track "count"');

## slave
my $itr_s_artist = $schema->resultset('Artist::Slave')->search;
is($itr_s_artist->count,COUNT_ARTIST,'slave artist "count"');

my $itr_s_cd = $schema->resultset('CD::Slave')->search;
is($itr_s_cd->count,COUNT_CD,'slave cd "count"');

my $itr_s_track = $schema->resultset('Track::Slave')->search;
is($itr_s_track->count,COUNT_TRACK,'slave track "count"');
