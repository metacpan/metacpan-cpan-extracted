#!perl

use strict;
use warnings;
$|=1;

use Test::More;
use File::Path;
use File::Spec;
use File::Path;

use lib 't';
use CTWS_Testing;

if(CTWS_Testing::has_environment()) { plan tests    => 5; }
else                                { plan skip_all => "Environment not configured"; }

ok( my $obj = CTWS_Testing::getObj(), "got object" );

eval "use Test::Database";
my $notd = $@ ? 1 : 0;

unless($notd) {
    my $td;
    if($td = Test::Database->handle( 'mysql' )) {
        #diag("deleting database: " . $td->name);
        $td->{driver}->drop_database($td->name);
    }
}

rmtree($obj->directory);    # remove stored config directory

if($^O =~ /Win32/i) {   # Windows cannot delete until after process has stopped
    ok(1);
} else {
    ok( ! -d $obj->directory,   'directory removed' );
}

# these shouldn't exist ...  whack just to be sure.
for my $d ('t/_DBDIR','t/_TMPDIR','t/_EXPECTED') {
    rmtree( $d ) if(-d $d);
    if($^O =~ /Win32/i) {
        ok(1);
    } else {
        ok( ! -d $d, "removed '$d' verified" );
    }
}
