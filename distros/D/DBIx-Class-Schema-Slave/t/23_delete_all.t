use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;
use DBICTest::Constants qw/ THROW_EXCEPTION_MESSAGE /;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 6 );
}

## slave
my $schema = DBICTest->init_schema;
my $message = THROW_EXCEPTION_MESSAGE;

my $itr_s_artist = $schema->resultset('Artist::Slave')->search;
eval{$itr_s_artist->delete_all};
like($@,qr/$message/,'slave artist "delete_all"');

my $itr_s_cd = $schema->resultset('CD::Slave')->search;
eval{$itr_s_cd->delete_all};
like($@,qr/$message/,'slave cd "delete_all"');

my $itr_s_track = $schema->resultset('Track::Slave')->search;
eval{$itr_s_track->delete_all};
like($@,qr/$message/,'slave track "delete_all"');

## master

my $itr_m_artist = $schema->resultset('Artist')->search;
$itr_m_artist->delete_all;
my $itr_m_artist_deleted = $schema->resultset('Artist')->search;
is($itr_m_artist_deleted->first,undef,'master artist "delete"');

my $itr_m_cd = $schema->resultset('CD')->search;
$itr_m_cd->delete_all;
my $itr_m_cd_deleted = $schema->resultset('CD')->search;
is($itr_m_cd_deleted->first,undef,'master cd "delete"');

my $itr_m_track = $schema->resultset('Track')->search;
$itr_m_track->delete_all;
my $itr_m_track_deleted = $schema->resultset('Track')->search;
is($itr_m_track_deleted->first,undef,'master track "delete"');
