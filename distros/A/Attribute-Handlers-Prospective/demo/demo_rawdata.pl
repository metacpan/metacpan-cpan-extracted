package UNIVERSAL;
use Attribute::Handlers;

sub Cooked : ATTR(SCALAR) { print "@{$_[4]}\n" }
sub PostRaw : ATTR(SCALAR,RAWDATA) { print $_[4], "\n" }
sub PreRaw : ATTR(SCALAR,RAWDATA) { print $_[4], "\n" }

package main;

my $x : Cooked(1..5);
my $y : PreRaw(1..5);
my $z : PostRaw(1..5);
