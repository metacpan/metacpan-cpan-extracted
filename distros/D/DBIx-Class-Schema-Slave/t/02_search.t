use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;
use DBICTest::Constants;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 1352 );
}

my $schema = DBICTest->init_schema;

# master
my @m_artist = $schema->resultset('Artist')->search;
is($_->is_slave,0,'master artist "search"') foreach @m_artist;
my $itr_m_artist = $schema->resultset('Artist')->search;
while ( my $m_artist = $itr_m_artist->next ) {
    is($m_artist->is_slave,0,'master artist "search"');
}

my @m_cd = $schema->resultset('CD')->search;
is($_->is_slave,0,'master cd "search"') foreach @m_cd;
my $itr_m_cd = $schema->resultset('CD')->search;
while ( my $m_cd = $itr_m_cd->next ) {
    is($m_cd->is_slave,0,'master cd "search"');
}

my @m_track = $schema->resultset('Track')->search;
is($_->is_slave,0,'master track "search"') foreach @m_track;
my $itr_m_track = $schema->resultset('Track')->search;
while ( my $m_track = $itr_m_track->next ) {
    is($m_track->is_slave,0,'master track "search"');
}

# slave
my @s_artist = $schema->resultset('Artist::Slave')->search;
is($_->is_slave, 1, 'slave artist "search"') foreach @s_artist;
my $itr_s_artist = $schema->resultset('Artist::Slave')->search;
while ( my $s_artist = $itr_s_artist->next ) {
    is($s_artist->is_slave, 1, 'slave artist "search"');
}

my @s_cd = $schema->resultset('CD::Slave')->search;
is($_->is_slave, 1, 'slave cd "search"') foreach @s_cd;
my $itr_s_cd = $schema->resultset('CD::Slave')->search;
while ( my $s_cd = $itr_s_cd->next ) {
    is($s_cd->is_slave, 1, 'slave cd "search"');
}

my @s_track = $schema->resultset('Track::Slave')->search;
is($_->is_slave, 1, 'slave track "search"') foreach @s_track;
my $itr_s_track = $schema->resultset('Track::Slave')->search;
while ( my $s_track = $itr_s_track->next ) {
    is($s_track->is_slave, 1, 'slave track "search"');
}
