use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;
use DBICTest::Constants qw/ ARTIST CD TRACK /;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 6 );
}

my $schema = DBICTest->init_schema;

## master
my @m_artist = $schema->resultset('Artist')->search({},{order_by => 'artistid ASC'})->get_column('name')->all;
is(@m_artist,ARTIST,'master artist "get_column"');

my @m_cd = $schema->resultset('CD')->search({},{order_by => 'cdid ASC'})->get_column('title')->all;
is(@m_cd,CD,'master cd "get_columb"');

my @m_track = $schema->resultset('Track')->search({},{order_by => 'trackid ASC'})->get_column('title')->all;
is(@m_track,TRACK,'master track "get_column"');

## slave
my @s_artist = $schema->resultset('Artist::Slave')->search({},{order_by => 'artistid ASC'})->get_column('name')->all;
is(@s_artist,ARTIST,'slave artist "get_column"');

my @s_cd = $schema->resultset('CD::Slave')->search({},{order_by => 'cdid ASC'})->get_column('title')->all;
is(@s_cd,CD,'slave cd "get_column"');

my @s_track = $schema->resultset('Track::Slave')->search({},{order_by => 'trackid ASC'})->get_column('title')->all;
is(@s_track,TRACK,'slave track "get_column"');

