#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Assert::Refute::T::Errors;

use Assert::Refute::Report;


dies_like {
    my $rep = Assert::Refute::Report->new;
    $rep->subcontract( sub { shift->ok(1) } );
} qr/^Assert::Refute.*[Nn]ame/, "no name = no game";
note $@;

dies_like {
    my $rep = Assert::Refute::Report->new;
    $rep->subcontract( "Ok, a name" => "This fails" );
} qr/^Assert::Refute.*must be.*code.*[Rreport]/, "Second must be ref";
note $@;

dies_like {
    my $rep = Assert::Refute::Report->new;
    $rep->subcontract( "Ok, a name" => Assert::Refute::Report->new );
} qr/^Assert::Refute.*must be.*finished/, "Unfinished report = no go";

dies_like {
    my $rep = Assert::Refute::Report->new;
    $rep->subcontract( "Ok, a name" => Assert::Refute::Report->new->done_testing, "Extra args" );
} qr/^Assert::Refute.*cannot take arg/, "Cannot add arguments to report";

done_testing;
