use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;
use DBICTest::Constants qw/ THROW_EXCEPTION_MESSAGE /;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 68 );
}

my $schema = DBICTest->init_schema;
my $message = THROW_EXCEPTION_MESSAGE;

## master
my $itr_m_artist = $schema->resultset('Artist')->search;
$itr_m_artist->update_all({name => 'UPDATE_ALL'});
while ( my $m_artist = $itr_m_artist->next ) {
    is($m_artist->is_slave,0,'master artist "update_all"');
    is($m_artist->name,'UPDATE_ALL','master artist "update_all"');
}

my $itr_m_cd = $schema->resultset('CD')->search;
$itr_m_cd->update_all({year => 'UPDATE_ALL'});
while ( my $m_cd = $itr_m_cd->next ) {
    is($m_cd->is_slave,0,'master cd "update_all"');
    is($m_cd->year,'UPDATE_ALL','master cd "update_all"');
}

## slave
my $itr_s_artist = $schema->resultset('Artist::Slave')->search;
eval{$itr_s_artist->update_all({name => 'UPDATE_ALL'})};
like($@,qr/$message/,'slave artist "update_all"');

my $itr_s_cd = $schema->resultset('CD::Slave')->search;
eval{$itr_s_cd->update_all({year => 'UPDATE_ALL'})};
like($@,qr/$message/,'slave artist "update_all"');
