use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 14 );
}

my $schema = DBICTest->init_schema;
my $cd_title = 'Tanz Walzer';
my $track_title = 'JUBILEE';

## master
my $m_artist = $schema->resultset('Artist')->find(1);
is($m_artist->is_slave,0,'master artist "search_related"');

my $m_cd = $m_artist->search_related('cds', {title => $cd_title},{order_by => 'cdid ASC'})->first;
is($m_cd->is_slave,0,'master cd "search_related"');
is($m_cd->title, $cd_title, 'master cd "search_related"');
my $m_artist_related = $m_cd->artist;
is($m_artist_related->is_slave,0,'master cd "search_related"');

my $m_track = $m_artist->cds->search_related('tracks', {'tracks.title' => $track_title},{order_by => 'trackid ASC'})->first;
is($m_track->is_slave,0,'master track "search_related"');
is($m_track->title, $track_title, 'master track "search_related"');
my $m_cd_related = $m_track->cd;
is($m_cd_related->is_slave,0,'master cd "search_related"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->find(1);
is($s_artist->is_slave,1,'slave artist "search_related"');

my $s_cd = $s_artist->search_related('cds', {title => $cd_title},{order_by => 'cdid ASC'})->first;
is($s_cd->is_slave,1,'slave cd "search_related"');
is($s_cd->title,$cd_title,'slave cd "search_related"');
my $s_artist_related = $s_cd->artist;
is($s_artist_related->is_slave,1,'slave cd "search_related"');

my $s_track = $s_artist->cds->search_related('tracks', {'tracks.title' => $track_title},{order_by => 'trackid ASC'})->first;
is($s_track->is_slave,1,'slave track "search_related"');
is($s_track->title, $track_title, 'slave track "search_related"');
my $s_cd_related = $s_track->cd;
is($s_cd_related->is_slave,1,'master cd "search_related"');
