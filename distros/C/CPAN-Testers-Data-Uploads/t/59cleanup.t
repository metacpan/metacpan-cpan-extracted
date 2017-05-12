#!/usr/bin/perl -w
use strict;

$|=1;

use Test::More tests => 2;
use File::Path;

eval "use Test::Database";
my $notd = $@ ? 1 : 0;

unless($notd) {
    my $td;
    if($td = Test::Database->handle( 'mysql' )) {
        $td->{driver}->drop_database($td->name);
    } elsif($td = Test::Database->handle( 'SQLite' )) {
        $td->{driver}->drop_database($td->name);
    }
}

for my $d ('t/_DBDIR') {
    ok( rmtree( $d ), "removed '$d'" );
    ok( ! -d $d,      "removed '$d' verified" );
}
