# run things under taint mode

use strict;
use warnings;
use Test::More qw( no_plan ); 

my $sid; 
use_ok( 'Apache::Session::PHP' );

CREATE: {
    tie my %session, 'Apache::Session::PHP', $sid, { SavePath => 't' };
    $session{ foo } = 'bar';
    $sid = $session{ _session_id };
    ok( -f "t/sess_$sid", 'session file created' );
}

RESTORE: {
    tie my %session, 'Apache::Session::PHP', $sid, { SavePath => 't' };
    is( $session{ foo }, 'bar', 'restore' );
}

DELETE: {
    ok( -f "t/sess_$sid", 'session file exists' );
    tie my %session, 'Apache::Session::PHP', $sid, { SavePath => 't' };
    tied( %session )->delete();
    ok( ! -f "t/sess_$sid", 'session file gone' );
}

