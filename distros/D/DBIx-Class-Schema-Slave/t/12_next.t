use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 676 );
}

my $schema = DBICTest->init_schema;

## master
my $m_itr_artist = $schema->resultset('Artist')->search;
while ( my $m_artist = $m_itr_artist->next ) {
    is($m_artist->is_slave,0,'Test master artist "next"');
}

my $m_itr_cd = $schema->resultset('CD')->search;
while ( my $m_cd = $m_itr_cd->next ) {
    is($m_cd->is_slave,0,'Test master cd "next"');
}

my $m_itr_track = $schema->resultset('Track')->search;
while ( my $m_track = $m_itr_track->next ) {
    is($m_track->is_slave,0,'Test master track "next"');
}

## slave
my $s_itr_artist = $schema->resultset('Artist::Slave')->search;
while ( my $s_artist = $s_itr_artist->next ) {
    is($s_artist->is_slave,1,'Test slave artist "next"');
}

my $s_itr_cd = $schema->resultset('CD::Slave')->search;
while ( my $s_cd = $s_itr_cd->next ) {
    is($s_cd->is_slave,1,'Test slave cd "next"');
}

my $s_itr_track = $schema->resultset('Track::Slave')->search;
while ( my $s_track = $s_itr_track->next ) {
    is($s_track->is_slave,1,'Test slave track "next"');
}

