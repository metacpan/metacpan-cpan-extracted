use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 6 );
}

my $schema = DBICTest->init_schema;
my $artist_name = 'QURULI';
my $cd_title = 'Tanz Walzer';
my $track_title = 'CLOCK';
my $count_artist = 1;
my $count_cd = 1;
my $count_track = 1;

## master
my $m_count_artist = $schema->resultset('Artist')->count_literal('name = ?',$artist_name);
is($m_count_artist,$count_artist,'master artist "count_literal"');

my $m_count_cd = $schema->resultset('CD')->count_literal('title = ?',$cd_title);
is($m_count_cd,$count_cd,'master cd "count_literal"');

my $m_count_track = $schema->resultset('Track')->count_literal('title = ?',$track_title);
is($m_count_track,$count_track,'master track "count_literal"');

## slave
my $s_count_artist = $schema->resultset('Artist::Slave')->count_literal('name = ?',$artist_name);
is($s_count_artist,$count_artist,'slave artist "count_literal"');

my $s_count_cd = $schema->resultset('CD::Slave')->count_literal('title = ?',$cd_title);
is($s_count_cd,$count_cd,'slave cd "count_literal"');

my $s_count_track = $schema->resultset('Track::Slave')->count_literal('title = ?',$track_title);
is($s_count_track,$count_track,'slave track "count_literal"');
