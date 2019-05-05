#!perl

use Data::Frame::Setup;

use Data::Frame::Examples qw(mtcars);
use PDL::Core qw(pdl);
use PDL::SV ();

use Test::LeakTrace;

my $mtcars = mtcars();

my $p = PDL::SV->new([1 .. 1000]);

leaktrace {
    #my $p1 = $p->copy;
    my $df = $mtcars->copy;
}; # -verbose;

