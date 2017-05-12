#!/usr/bin/perl 

# Copyright (c) 2006 Mark Hedges <hedges@ucsd.edu>

use strict;
use English '-no_match_vars';

use blib;

use Test::More tests => 6;

use FindBin;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
BEGIN {
    use_ok('CGI::FormBuilder');
}
require_ok('CGI::FormBuilder');

# Need to fake a request or else we stall... or not?  hrmm.
$ENV{REQUEST_METHOD} = 'GET';
my $testqs = {
    test1   => 'testing',
    test2   => 'test@test.foo',
    test3   => 0,
    _submitted_test => 1,
};
$ENV{QUERY_STRING} = join('&', map "$_=$testqs->{$_}", keys %{$testqs});

sub test4opts {
    return [
        [ beef => "Where's the beef?"   ],
        [ chicken => "Cross the road!"  ],
        [ horta => "They're eggs, Jim!" ],
    ];
}

my $form = undef;

my $sourcefile = "$FindBin::Bin/test.fb";

eval {
    $form = CGI::FormBuilder->new(
        source  => {
            type    => 'YAML',
            source  => $sourcefile,
            debug   => 0,
        },
    );
};
ok !$EVAL_ERROR, 'create form';

my $ren = undef;

eval {
    $ren = $form->render;
};
ok !$EVAL_ERROR, 'render form';

ok( $form->submitted, 'form submitted' );

ok( $form->validate, 'form validate' );

