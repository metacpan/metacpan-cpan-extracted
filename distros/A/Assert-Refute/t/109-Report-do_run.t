#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 4;

use Assert::Refute;

my $rep = Assert::Refute::Report->new->do_run( sub { refute 0, "Ok"; } );

is $rep->get_sign, "t1d", "Happy case";

$rep = Assert::Refute::Report->new->do_run( sub { refute 1, "Broken promise"; } );

is $rep->get_sign, "tNd", "Failed test";

$rep = Assert::Refute::Report->new->do_run( sub { die "Foobared" } );

is $rep->get_sign, "tE", "Interrupt";
like $rep->get_error, qr/^Foobared at/, "Exception retained";

