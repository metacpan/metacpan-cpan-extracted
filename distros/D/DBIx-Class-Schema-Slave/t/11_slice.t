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
my $artist_name = 'Spangle call Lilli line';
my $cd_title = 'TRACE';
my $track_title = 'mila';

## master
my $m_artist = $schema->resultset('Artist')->search({},{order_by => 'artistid ASC'})->slice(1,1)->first;
is($m_artist->is_slave,0,'master artist "slice"');
is($m_artist->name,$artist_name,'master artist "slice"');

my $m_cd = $schema->resultset('CD')->search({},{order_by => 'cdid ASC'})->slice(1,1)->first;
is($m_cd->is_slave, 0, 'master cd "slice"');
is($m_cd->title,$cd_title,'master cd "slice"');

my $m_track = $schema->resultset('Track')->search({},{order_by => 'trackid ASC'})->slice(14,21)->first;
is($m_track->is_slave, 0, 'master track "slice"');
is($m_track->title,$track_title,'master track "slice"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->search({},{order_by => 'artistid ASC'})->slice(1,1)->first;
is($s_artist->is_slave,1,'slave artist "slice"');
is($s_artist->name, $artist_name, 'slave artist "slice"');

my $s_cd = $schema->resultset('CD::Slave')->search({},{order_by => 'cdid ASC'})->slice(1,1)->first;
is($s_cd->is_slave,1,'slave cd "slice"');
is($s_cd->title, $cd_title, 'slave cd "slice"');

my $s_track = $schema->resultset('Track::Slave')->search({},{order_by => 'trackid ASC'})->slice(14,21)->first;
is($s_track->is_slave,1,'slave track "slice"');
is($s_track->title,$track_title,'slave track "slice"');
