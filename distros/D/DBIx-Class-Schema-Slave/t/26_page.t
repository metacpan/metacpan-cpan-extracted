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

## master
my $m_artist_rs = $schema->resultset('Artist')->page(1);
is($m_artist_rs->first->is_slave,0,'master artist "page"');

my $m_cd_rs = $schema->resultset('CD')->page(1);
is($m_cd_rs->first->is_slave,0,'master cd "page"');

my $m_track_rs = $schema->resultset('Track')->page(1);
is($m_track_rs->first->is_slave,0,'master track "page"');

## slave
my $s_artist_rs = $schema->resultset('Artist::Slave')->page(1);
is($s_artist_rs->first->is_slave,1,'slave artist "page"');

my $s_cd_rs = $schema->resultset('CD::Slave')->page(1);
is($s_cd_rs->first->is_slave,1,'slave cd "page"');

my $s_track_rs = $schema->resultset('Track::Slave')->page(1);
is($s_track_rs->first->is_slave,1,'slave track "page"');
