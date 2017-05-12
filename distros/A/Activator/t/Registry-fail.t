#!/usr/bin/perl -w

use Test::More tests => 2;
use Activator::Registry;
use IO::Capture::Stderr;
# bad file warns

my $capture = IO::Capture::Stderr->new();
my $line;
$capture->start();
my $badobj = Activator::Registry->new('foo');
$capture->stop();
$line = $capture->read;
warn $line;
ok( $line =~ /\[WARN\].*foo/, 'bad file warns' );

$badobj->register('key', 'value');
my $val = $badobj->get( 'key' );
ok( $val eq 'value', 'unloaded registry still works to register values');
