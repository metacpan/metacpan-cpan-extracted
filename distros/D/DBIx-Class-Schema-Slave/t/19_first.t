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
my $m_artist = $schema->resultset('Artist')->search({},{order_by => 'artistid ASC'})->first;
is($m_artist->is_slave,0,'master artist "first"');

my $m_cd = $schema->resultset('CD')->search({},{order_by => 'cdid ASC'})->first;
is($m_cd->is_slave,0,'master cd "first"');

my $m_track = $schema->resultset('Track')->search({},{order_by => 'trackid ASC'})->first;
is($m_track->is_slave,0,'master track "first"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->search({},{order_by => 'artistid ASC'})->first;
is($s_artist->is_slave,1,'slave artist "first"');

my $s_cd = $schema->resultset('CD::Slave')->search({},{order_by => 'cdid ASC'})->first;
is($s_cd->is_slave,1,'slave cd "first"');

my $s_track = $schema->resultset('Track::Slave')->search({},{order_by => 'trackid ASC'})->first;
is($s_track->is_slave,1,'slave track "first"');
