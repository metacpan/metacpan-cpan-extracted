#!/usr/local/bin/perl
use strict;
use warnings;
use Benchmark qw/timethese cmpthese/;

{
    package X;
    sub new { bless {}, shift }
    sub meth {
	$_[0]->{meth} = $_[1] if @_ >= 2;
	$_[0]->{meth};
    }
    sub lvmeth : lvalue {
	$_[0]->{lvmeth}
    }
}

my $x = X->new();
$x->meth(1);
$x->lvmeth = 2;

print "#### Accessor\n";
cmpthese(timethese(0, {
    normal => sub {
	$x->meth == 1 or die;
    },
    axelerated => sub {
	use Class::Axelerator;
	$x->meth == 1 or die;
	no Class::Axelerator;
    }
		   }));
print "#### Mutator\n";
cmpthese(timethese(0, {
    normal => sub {
	$x->meth(2);
    },
    axelerated => sub {
	use Class::Axelerator;
	$x->meth = 2;
	no Class::Axelerator;
    }
		   }));
print "#### Lvalue Mutator\n";
cmpthese(timethese(0, {
    normal => sub {
	$x->lvmeth = 2;
    },
    axelerated => sub {
	use Class::Axelerator;
	$x->lvmeth = 2;
	no Class::Axelerator;
    }
		   }));
