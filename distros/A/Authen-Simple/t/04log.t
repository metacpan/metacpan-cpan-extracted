#!perl

use strict;
use warnings;

use Authen::Simple::Log;
use IO::File;

my @levels = qw( debug error info warn );

use Test::More tests => 7;

ok( my $log    = Authen::Simple::Log->new, 'Instance' );
ok( my $stderr = IO::File->new_tmpfile,    'Temporary file' );
can_ok( $log, @levels );

{
    local *STDERR = $stderr;

    local $^W = 0;
    
    foreach my $level ( @levels ) {
        $log->$level($level);
    }

    local $^W = 1;

    foreach my $level ( @levels ) {
        $log->$level($level);
    }
}

$stderr->seek( 0, 0 );

my @messages = $stderr->getlines;

ok( @messages == 3, 'Got three messages' );
like( $messages[0], qr/\[error\] \[main\] error$/, 'First log message' );
like( $messages[1], qr/\[error\] \[main\] error$/, 'Second log message' );
like( $messages[2], qr/\[warn\] \[main\] warn$/,   'Third log message' );
