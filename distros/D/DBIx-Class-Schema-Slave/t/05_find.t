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
my $artist_name = "QURULI";
my $cd_title = 'Tanz Walzer';
my $track_title = 'HEILIGENSTADT';

## master
my $m_artist = $schema->resultset('Artist')->find(1);
is($m_artist->is_slave,0,'master artist "find"');
is($m_artist->name,$artist_name,'master artist "find"');

my $m_cd = $schema->resultset('CD')->find(1);
is($m_cd->is_slave,0,'master cd "find"');
is($m_cd->title,$cd_title,'master cd "find"');

my $m_track = $schema->resultset('Track')->find(1);
is($m_track->is_slave,0,'master track "find"');
is($m_track->title,$track_title,'master track "find"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->find(1);
is($s_artist->is_slave,1,'slave artist "find"');
is($s_artist->name,$artist_name,'slave artist "find"');

my $s_cd = $schema->resultset('CD::Slave')->find(1);
is($s_cd->is_slave,1,'slave cd "find"');
is($s_cd->title,$cd_title,'slave cd "find"');

my $s_track = $schema->resultset('Track::Slave')->find(1);
is($s_track->is_slave,1,'slave track "find"');
is($s_track->title,$track_title,'slave track "find"');

