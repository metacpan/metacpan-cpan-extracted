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
my @m_artist = $schema->resultset('Artist')->search_rs;
while ( my $m_artist = $m_artist[0]->next ) {
    is($m_artist->is_slave,0,'master artist "search_rs"');
}
my $itr_m_artist = $schema->resultset('Artist')->search_rs;
while ( my $m_artist = $itr_m_artist->next ) {
    is($m_artist->is_slave,0,'master artist "search_rs"');
}

my @m_cd = $schema->resultset('CD')->search_rs;
while ( my $m_cd = $m_cd[0]->next ) {
    is($m_cd->is_slave,0,'master cd "search_rs"');
}
my $itr_m_cd = $schema->resultset('CD')->search_rs;
while ( my $m_cd = $itr_m_cd->next ) {
    is($m_cd->is_slave,0,'master cd "search_rs"');
}

my @m_track = $schema->resultset('Track')->search_rs;
while ( my $m_track = $m_track[0]->next ) {
    is($m_track->is_slave,0,'master track "search_rs"');
}
my $itr_m_track = $schema->resultset('Track')->search_rs;
while ( my $m_track = $itr_m_track->next ) {
    is($m_track->is_slave,0,'master track "search_rs"');
}

## slave
my @s_artist = $schema->resultset('Artist::Slave')->search_rs;
while ( my $s_artist = $s_artist[0]->next ) {
    is($s_artist->is_slave,1,'slave artist "search_rs"');
}
my $itr_s_artist = $schema->resultset('Artist::Slave')->search_rs;
while ( my $s_artist = $itr_s_artist->next ) {
    is($s_artist->is_slave,1,'slave artist "search_rs"');
}

my @s_cd = $schema->resultset('CD::Slave')->search_rs;
while ( my $s_cd = $s_cd[0]->next ) {
    is($s_cd->is_slave,1,'slave cd "search"');
}
my $itr_s_cd = $schema->resultset('CD::Slave')->search_rs;
while ( my $s_cd = $itr_s_cd->next ) {
    is($s_cd->is_slave,1,'slave cd "search_rs"');
}

my @s_track = $schema->resultset('Track::Slave')->search_rs;
while ( my $s_track = $s_track[0]->next ) {
    is($s_track->is_slave,1,'slave track "search_rs"');
}
my $itr_s_track = $schema->resultset('Track::Slave')->search_rs;
while ( my $s_track = $itr_s_track->next ) {
    is($s_track->is_slave,1,'slave track "search_rs"');
}
