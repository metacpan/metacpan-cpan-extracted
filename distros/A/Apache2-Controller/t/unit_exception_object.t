#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use blib;

use English '-no_match_vars';

use Log::Log4perl qw(:easy);

use Test::More qw( no_plan );

use Apache2::Controller::X;

eval { Apache2::Controller::X->throw('horta') };
is("$EVAL_ERROR" => 'horta', 'stringify exception throw works');

eval { Apache2::Controller::X->throw('spock') };
my $X = Exception::Class->caught('Apache2::Controller::X');
ok(defined $X, 'X object is defined after class throw');
SKIP: {
    skip 'X object not defined', 2 unless defined $X;
    isa_ok($X, 'Apache2::Controller::X', 'X isa Apache2::Controller::X');
    can_ok($X, qw( trace message dump status status_line ));
};

eval { a2cx 'mccoy' };
$X = Exception::Class->caught('Apache2::Controller::X');
ok(defined $X, 'X object is defined after alias a2cx');
