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
        : ( tests => 684 );
}

## slave
my $schema = DBICTest->init_schema;
my $message = THROW_EXCEPTION_MESSAGE;

my $itr_s_artist = $schema->resultset('Artist::Slave')->search;
while ( my $s_artist = $itr_s_artist->next ) {
    is($s_artist->is_slave,1,'slave artist "delete"');
    eval{$s_artist->delete};
    like($@,qr/$message/,'slave artist "delete"');
}

my $itr_s_cd = $schema->resultset('CD::Slave')->search;
while ( my $s_cd = $itr_s_cd->next ) {
    is($s_cd->is_slave,1,'slave cd "delete"');
    eval{$s_cd->delete};
    like($@,qr/$message/,'slave cd "delete"');
}

my $itr_s_track = $schema->resultset('Track::Slave')->search;
while ( my $s_track = $itr_s_track->next ) {
    is($s_track->is_slave,1,'slave track "delete"');
    eval{$s_track->delete};
    like($@,qr/$message/,'slave track "delete"');
}

## master

my $itr_m_artist = $schema->resultset('Artist')->search;
while ( my $m_artist = $itr_m_artist->next ) {
    is($m_artist->is_slave,0,'master artist "delete"');
    $m_artist->delete;
}
my $itr_m_artist_deleted = $schema->resultset('Artist')->search;
is($itr_m_artist_deleted->first,undef,'master artist "delete"');

my $itr_m_cd = $schema->resultset('CD')->search;
while ( my $m_cd = $itr_m_cd->next ) {
    is($m_cd->is_slave,0,'master cd "delete"');
    $m_cd->delete;
}
my $itr_m_cd_deleted = $schema->resultset('CD')->search;
is($itr_m_cd_deleted->first,undef,'master cd "delete"');

my $itr_m_track = $schema->resultset('Track')->search;
while ( my $m_track = $itr_m_track->next ) {
    is($m_track->is_slave,0,'master track "delete"');
    $m_track->delete;
}
my $itr_m_track_deleted = $schema->resultset('Track')->search;
is($itr_m_track_deleted->first,undef,'master track "delete"');
