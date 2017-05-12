use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 676 );
}

my $schema = DBICTest->init_schema;

## master
my @m_artist = $schema->resultset('Artist')->all;
foreach my $m_artist ( @m_artist ) {
    is($m_artist->is_slave,0,'master artist "all"');
}

my @m_cd = $schema->resultset('CD')->all;
foreach my $m_cd ( @m_cd ) {
    is($m_cd->is_slave,0,'master cd "all"');
}

my @m_track = $schema->resultset('Track')->all;
foreach my $m_track ( @m_track ) {
    is($m_track->is_slave,0,'master track "all"');
}

## slave
my @s_artist = $schema->resultset('Artist::Slave')->all;
foreach my $s_artist ( @s_artist ) {
    is($s_artist->is_slave,1,'slave artist "all"');
}

my @s_cd = $schema->resultset('CD::Slave')->all;
foreach my $s_cd ( @s_cd ) {
    is($s_cd->is_slave,1,'slave cd "all"');
}

my @s_track = $schema->resultset('Track::Slave')->all;
foreach my $s_track ( @s_track ) {
    is($s_track->is_slave,1,'slave track "all"');
}
