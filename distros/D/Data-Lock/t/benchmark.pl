#!perl
#
# $Id: benchmark.pl,v 1.1 2013/04/03 14:37:57 dankogai Exp $
#
use strict;
use warnings;
use Benchmark qw/timethese cmpthese/;
use Data::Lock qw/dlock dunlock/;
use Attribute::Constant;
use Readonly;

dlock my $sd = 1;
my $sa : Constant(1);
Readonly my $sr => 1;
local *sg = \1; our $sg;

cmpthese(
    timethese(
        0,
        {
            dlock => sub {
                eval { $sd++ }; die unless $@; $sd == 1 or die;
            },
            Attribute => sub{
                eval { $sa++ }; die unless $@; $sa == 1 or die;
            },
            Readonly => sub {
                eval { $sr++ }; die unless $@; $sr == 1 or die;
            },
            glob => sub {
                eval { $sg++ }; die unless $@; $sg == 1 or die;
            },
        }
    )
);

dlock my $da = [ 1 .. 1000 ];
my @aa : Constant( 1 .. 1000 );
Readonly my @ar => ( 1 .. 1000 );

cmpthese(
    timethese(
        0,
        {
            dlock => sub{
		eval { pop @$da }; die unless $@; $da->[0] == 1 or die;
	    },
            Attribute => sub{
		eval { pop @aa }; die unless $@; $aa[0] == 1 or die;
	    },
            Readonly => sub {
		eval { pop @ar }; die unless $@; $ar[0] == 1 or die;
	    },
	}
    )
);

dlock my $dh = { map { $_ => $_*$_ } 1 .. 1000 }; 
my %ha : Constant( map { $_ => $_*$_ } 1 .. 1000 );
Readonly my %hr => ( map { $_ => $_ * $_ } 1 .. 1000 );

cmpthese(
    timethese(
        0,
        {
            dlock => sub{
		eval { $dh->{zero}++ }; die unless $@; $dh->{1000} == 1e6 or die;
	    },
	    Attribute => sub{
		eval { $ha{zero}++ }; die unless $@; $ha{1000} == 1e6 or die;
	    },
            Readonly => sub {
		eval { $hr{zero}++ }; die unless $@; $hr{1000} == 1e6 or die;
	    },
        }
    )
);
