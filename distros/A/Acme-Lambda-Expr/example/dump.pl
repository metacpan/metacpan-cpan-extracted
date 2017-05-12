#!perl -w
use strict;
use Acme::Lambda::Expr qw(:all);
use Data::Dumper;

my $f = abs($x - $y) ** 2;

print $f->deparse, "\n";

my $dx = Data::Dumper->new([$f], ['f']);
print $dx->Sortkeys(1)->Quotekeys(0)->Dump();
