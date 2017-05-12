#!/usr/bin/perl -w
use strict;

$|=1;

use File::Path;
use Test::More tests => 2;

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

for my $d ('t/_DBDIR','test') {
    rmtree( $d ) if(-d $d);
    if($^O =~ /Win32/i) {
        ok(1);
    } else {
        ok( ! -d $d, "removed '$d' verified" );
    }
}
