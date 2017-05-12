use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 682 );
}

my $schema = DBICTest->init_schema;
my $artist = {artistid => 1};

## master
my $m_artist_resultset = $schema->resultset('Artist');
my @m_artist = $m_artist_resultset->search;
# set cache
$m_artist_resultset->set_cache( \@m_artist );
# get cache
my $m_cache_artist = $m_artist_resultset->get_cache;
foreach my $m_cache_artist ( @{$m_cache_artist} ) {
    is($m_cache_artist->is_slave,0,'master artist "set_get_clear_cache"');
}
# clear cache
$m_artist_resultset->clear_cache;
is($m_artist_resultset->get_cache,undef,'master artist "set_get_clear_cache"');


my $m_cd_resultset = $schema->resultset('CD');
my @m_cd = $m_cd_resultset->search;
# set cache
$m_cd_resultset->set_cache( \@m_cd );
# get cache
my $m_cache_cd = $m_cd_resultset->get_cache;
foreach my $m_cache_cd ( @{$m_cache_cd} ) {
    is($m_cache_cd->is_slave,0,'master cd "set_get_clear_cache"');
}
# clear cache
$m_cd_resultset->clear_cache;
is($m_cd_resultset->get_cache,undef,'master cd "set_get_clear_cache"');

my $m_track_resultset = $schema->resultset('Track');
my @m_track = $m_track_resultset->search;
# set cache
$m_track_resultset->set_cache( \@m_track );
# get cache
my $m_cache_track = $m_track_resultset->get_cache;
foreach my $m_cache_track ( @{$m_cache_track} ) {
    is($m_cache_track->is_slave,0,'master track "set_get_clear_cache"');
}
# clear cache
$m_track_resultset->clear_cache;
is($m_track_resultset->get_cache,undef,'master track "set_get_clear_cache"');

## slave
my $s_artist_resultset = $schema->resultset('Artist::Slave');
my @s_artist = $s_artist_resultset->search;
# set cache
$s_artist_resultset->set_cache( \@s_artist );
# get cache
my $s_cache_artist = $s_artist_resultset->get_cache;
foreach my $s_cache_artist ( @{$s_cache_artist} ) {
    is($s_cache_artist->is_slave,1,'slave artist "set_get_clear_cache"');
}
# clear cache
$s_artist_resultset->clear_cache;
is($s_artist_resultset->get_cache,undef,'slave artist "set_get_clear_cache"');


my $s_cd_resultset = $schema->resultset('CD::Slave');
my @s_cd = $s_cd_resultset->search;
# set cache
$s_cd_resultset->set_cache( \@s_cd );
# get cache
my $s_cache_cd = $s_cd_resultset->get_cache;
foreach my $s_cache_cd ( @{$s_cache_cd} ) {
    is($s_cache_cd->is_slave,1,'slave cd "set_get_clear_cache"');
}
# clear cache
$s_cd_resultset->clear_cache;
is($s_cd_resultset->get_cache,undef,'slave cd "set_get_clear_cache"');

my $s_track_resultset = $schema->resultset('Track::Slave');
my @s_track = $s_track_resultset->search;
# set cache
$s_track_resultset->set_cache( \@s_track );
# get cache
my $s_cache_track = $s_track_resultset->get_cache;
foreach my $s_cache_track ( @{$s_cache_track} ) {
    is($s_cache_track->is_slave,1,'slave track "set_get_clear_cache"');
}
# clear cache
$s_track_resultset->clear_cache;
is($s_track_resultset->get_cache,undef,'slave track "set_get_clear_cache"');
