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
my $rows = 10;

## master
my $pager_m_artist = $schema->resultset('Artist')->search({},{page=>1,rows=>$rows})->pager;
is($pager_m_artist->entries_per_page,10,'master artist "pager"');

my $pager_m_cd = $schema->resultset('CD')->search({},{page=>1,rows=>$rows})->pager;
is($pager_m_cd->entries_per_page,10,'master cd "pager"');

my $pager_m_track = $schema->resultset('Track')->search({},{page=>1,rows=>$rows})->pager;
is($pager_m_track->entries_per_page,10,'master track "pager"');

## slave
my $pager_s_artist = $schema->resultset('Artist::Slave')->search({},{page=>1,rows=>$rows})->pager;
is($pager_s_artist->entries_per_page,10,'slave artist "pager"');

my $pager_s_cd = $schema->resultset('CD::Slave')->search({},{page=>1,rows=>$rows})->pager;
is($pager_s_cd->entries_per_page,10,'slave cd "pager"');

my $pager_s_track = $schema->resultset('Track::Slave')->search({},{page=>1,rows=>$rows})->pager;
is($pager_s_track->entries_per_page,10,'slave track "pager"');
