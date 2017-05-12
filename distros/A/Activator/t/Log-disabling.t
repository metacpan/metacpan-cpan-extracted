#!perl
use warnings;
use strict;

BEGIN {
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/Log-disabling.yml";
}

use Activator::Log;
use IO::Capture::Stderr;
use Test::More tests => 3;

my ( $line, $capture );

Activator::Log::level( 'TRACE' );
$capture = IO::Capture::Stderr->new();
$capture->start();
Activator::Log->TRACE('TRACE');
Activator::Log->DEBUG('DEBUG');
$capture->stop();
$line = $capture->read;
ok ( $line =~ /\[DEBUG\] DEBUG \(main::/, "disable works from script" );

$capture->start();
&Test::outp();
$capture->stop();
$line = $capture->read;
ok ( $line =~ /\[DEBUG\] DEBUG /, "disable works from top level class" );


$capture->start();
&Test::Nested::outp();
$capture->stop();
$line = $capture->read;
ok ( $line =~ /\[DEBUG\] DEBUG /, "disable works from subclass" );

#$capture->start();
#&Test::Nested::outp();
#$capture->stop();
#my $line = $capture->read;
#ok ( $line =~ /\[DEBUG\] DEBUG /, "disable works for subclass trees" );

package Test;
sub outp {
    Activator::Log->TRACE('TRACE');
    Activator::Log->DEBUG('DEBUG');
}

package Test::Nested;
sub outp {
    Activator::Log->TRACE('TRACE');
    Activator::Log->DEBUG('DEBUG');
}
