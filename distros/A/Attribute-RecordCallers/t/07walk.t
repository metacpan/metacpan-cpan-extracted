#!perl

use strict;
use warnings;
use Test::More tests => 1;
use Attribute::RecordCallers;

sub flutter::shy : RecordCallers { }
sub pinky::pie   : RecordCallers { }

flutter::shy;
pinky::pie;
package flutter; shy;
package pinky  ; pie for 1,2;

package main;

my $report = '';
Attribute::RecordCallers::walk( sub {
    my ($f, $calls) = @_;
    $report .= "$f,".(join ",", map "$_->[0],$_->[2]", @$calls)."\n";
} );
is($report, <<REPORT);
flutter::shy,main,11,flutter,13
pinky::pie,main,12,pinky,14,pinky,14
REPORT
