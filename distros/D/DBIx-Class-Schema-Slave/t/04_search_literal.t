use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 12 );
}

my $schema = DBICTest->init_schema;

## master
my @m_artist = $schema->resultset('Artist')->search_literal('name = ?', 'QURULI');
foreach my $m_artist ( @m_artist ) {
    is($m_artist->is_slave,0,'master artist "search_literal"');
}
my $itr_m_artist = $schema->resultset('Artist')->search_literal('name = ?', 'QURULI');
while ( my $m_artist = $itr_m_artist->next ) {
    is($m_artist->is_slave,0,'master artist "search_literal"');
}

my @m_cd = $schema->resultset('CD')->search_literal('title = ?', 'Tanz Walzer');
foreach my $m_cd ( @m_cd ) {
    is($m_cd->is_slave,0,'master cd "search_literal"');
}
my $itr_m_cd = $schema->resultset('CD')->search_literal('title = ?', 'Tanz Walzer');
while ( my $m_cd = $itr_m_cd->next ) {
    is($m_cd->is_slave,0,'master cd "search_literal"');
}

my @m_track = $schema->resultset('Track')->search_literal('title = ?', 'JUBILEE');
foreach my $m_track ( @m_track ) {
    is($m_track->is_slave,0,'master track "search_literal"');
}
my $itr_m_track = $schema->resultset('Track')->search_literal('title = ?', 'JUBILEE');
while ( my $m_track = $itr_m_track->next ) {
    is($m_track->is_slave,0,'slave track "search_literal"');
}

## slave
my @s_artist = $schema->resultset('Artist::Slave')->search_literal('name = ?', 'QURULI');
foreach my $s_artist ( @s_artist ) {
    is($s_artist->is_slave,1,'slave artist "search_literal"');
}
my $itr_s_artist = $schema->resultset('Artist::Slave')->search_literal('name = ?', 'QURULI');
while ( my $s_artist = $itr_s_artist->next ) {
    is($s_artist->is_slave,1,'slave artist "search_literal"');
}

my @s_cd = $schema->resultset('CD::Slave')->search_literal('title = ?', 'Tanz Walzer');
foreach my $s_cd ( @s_cd ) {
    is($s_cd->is_slave,1,'slave cd "search_literal"');
}
my $itr_s_cd = $schema->resultset('CD::Slave')->search_literal('title = ?', 'Tanz Walzer');
while ( my $s_cd = $itr_s_cd->next ) {
    is($s_cd->is_slave,1,'slave cd "search_literal"');
}

my @s_track = $schema->resultset('Track::Slave')->search_literal('title = ?', 'JUBILEE');
foreach my $s_track ( @s_track ) {
    is($s_track->is_slave,1,'slave track "search_literal"');
}
my $itr_s_track = $schema->resultset('Track::Slave')->search_literal('title = ?', 'JUBILEE');
while ( my $s_track = $itr_s_track->next ) {
    is($s_track->is_slave,1,'slave track "search_literal"');
}
