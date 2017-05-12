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
my $track_title = 'R.G.B.';

## master
my $m_artist = $schema->resultset('Artist')->search_like({name => '%call%'},{order_by => 'artistid ASC'})->first;
is($m_artist->is_slave,0,'master artist "search_like"');
is($m_artist->name,$artist_name,'master artist "search_like"');

my $m_cd = $schema->resultset('CD')->search_like({title => 'TR%'},{order_by => 'cdid ASC'})->first;
is($m_cd->is_slave,0,'master cd "search_like"');
is($m_cd->title,$cd_title,'master cd "search_like"');

my $m_track = $schema->resultset('Track')->search_like({'title' => '%B.'},{order_by => 'trackid ASC'})->first;
is($m_track->is_slave,0,'master track "search_like"');
is($m_track->title,$track_title,'master track "search_like"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->search_like({name => '%call%'},{order_by => 'artistid ASC'})->first;
is($s_artist->is_slave,1,'slave artist "search_like"');
is($s_artist->name,$artist_name,'slave artist "search_like"');

my $s_cd = $schema->resultset('CD::Slave')->search_like({title => 'TR%'},{order_by => 'cdid ASC'})->first;
is($s_cd->is_slave,1,'slave cd "search_like"');
is($s_cd->title,$cd_title,'slave cd "search_like"');

my $s_track = $schema->resultset('Track::Slave')->search_like({'title' => '%B.'},{order_by => 'trackid ASC'})->first;
is($s_track->is_slave,1,'slave track "search_like"');
is($s_track->title,$track_title,'slave track "search_like"');
