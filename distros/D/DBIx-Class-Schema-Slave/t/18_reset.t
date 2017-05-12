use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 1352 );
}

my $schema = DBICTest->init_schema;

## master
my $itr_m_artist = $schema->resultset('Artist')->search;
while ( my $m_artist = $itr_m_artist->next ) {
    is($m_artist->is_slave,0,'master artist "reset"');
}
$itr_m_artist->reset;
while ( my $m_artist = $itr_m_artist->next ) {
    is($m_artist->is_slave,0,'master artist "reset"');
}

my $itr_m_cd = $schema->resultset('CD')->search;
while ( my $m_cd = $itr_m_cd->next ) {
    is($m_cd->is_slave,0,'master cd "reset"');
}
$itr_m_cd->reset;
while ( my $m_cd = $itr_m_cd->next ) {
    is($m_cd->is_slave,0,'master cd "reset"');
}

my $itr_m_track = $schema->resultset('Track')->search;
while ( my $m_track = $itr_m_track->next ) {
    is($m_track->is_slave,0,'master track "reset"');
}
$itr_m_track->reset;
while ( my $m_track = $itr_m_track->next ) {
    is($m_track->is_slave,0,'master track "reset"');
}

## slave
my $itr_s_artist = $schema->resultset('Artist::Slave')->search;
while ( my $s_artist = $itr_s_artist->next ) {
    is($s_artist->is_slave,1,'slave artist "reset"');
}
$itr_s_artist->reset;
while ( my $s_artist = $itr_s_artist->next ) {
    is($s_artist->is_slave,1,'slave artist "reset"');
}

my $itr_s_cd = $schema->resultset('CD::Slave')->search;
while ( my $s_cd = $itr_s_cd->next ) {
    is($s_cd->is_slave,1,'slave cd "reset"');
}
$itr_s_cd->reset;
while ( my $s_cd = $itr_s_cd->next ) {
    is($s_cd->is_slave,1,'slave cd "reset"');
}

my $itr_s_track = $schema->resultset('Track::Slave')->search;
while ( my $s_track = $itr_s_track->next ) {
    is($s_track->is_slave,1,'slave track "reset"');
}
$itr_s_track->reset;
while ( my $s_track = $itr_s_track->next ) {
    is($s_track->is_slave,1,'slave track "reset"');
}

