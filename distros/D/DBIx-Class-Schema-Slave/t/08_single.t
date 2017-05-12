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
my $artist = 'Spangle call Lilli line';
my $cd = 'TRACE';
my $track = 'U-Lite';

## master
my $m_artist = $schema->resultset('Artist')->search({name => $artist},{order_by => 'artistid ASC'})->single;
is( $m_artist->is_slave,0,'master artist "single"');
is( $m_artist->name,$artist,'master artist "single"');

my $m_cd = $schema->resultset('CD')->search({title => $cd},{order_by => 'cdid ASC'})->single;
is( $m_cd->is_slave, 0, 'Single master artist');
is( $m_cd->title,$cd,'master cd "single"');

my $m_track = $schema->resultset('Track')->search({title => $track},{order_by => 'trackid ASC'})->single;
is( $m_track->is_slave, 0, 'Single master artist');
is( $m_track->title,$track,'master track "single"');

## slave
my $s_artist = $schema->resultset('Artist::Slave')->search({name => $artist},{order_by => 'artistid ASC'})->single;
is( $s_artist->is_slave, 1, 'Single slave artist');
is( $s_artist->name,$artist,'slave artist "single"');

my $s_cd = $schema->resultset('CD::Slave')->search({title => $cd},{order_by => 'cdid ASC'})->single;
is( $s_cd->is_slave, 1, 'Single slave artist');
is( $s_cd->title,$cd,'slave cd "single"');

my $s_track = $schema->resultset('Track::Slave')->search({title => $track},{order_by => 'trackid ASC'})->single;
is( $s_track->is_slave, 1, 'Single slave artist');
is( $s_track->title,$track,'slave track "single"');
