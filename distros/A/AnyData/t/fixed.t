#!/usr/local/bin/perl -wT
use strict;
use warnings;

use Test::More;
plan tests => 6;

use AnyData;

my $table = adTie( 'Fixed', 't/fixed.tbl', 'r', { pattern => 'A11 A2' } );

ok( 6 == adRows($table), "Failed rows" );
ok( 'au' eq $table->{'australia'}->{code},   'select one' );
ok( 'ch' eq $table->{'switzerland'}->{code}, 'select another' );
ok( '0'  eq $table->{'broken'}->{code},      'select another' );
ok( ' 0' eq $table->{'broken2'}->{code},     'select another' );

#write test
ok(
    <<'HERE' eq adExport( $table, 'Fixed', undef, { pattern => 'A11 A2' } ), 'export fixed format' );
country    co
australia  au
germany    de
france     fr
switzerlandch
broken     0 
broken2     0
HERE

#TODO: note that the docco says the column names need to be comma separated, and the input file has 'country,code', thus the written file would be busted too

__END__
