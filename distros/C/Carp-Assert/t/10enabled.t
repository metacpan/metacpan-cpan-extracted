#!/usr/bin/perl -w

# Test with assert on.

use strict;
use Test::More tests => 7;

# Make sure we're shielded against the user possibly having
# NDEBUG or PERL_NDEBUG set.  Localize the changes because changes
# to %ENV persist across processes in VMS.
BEGIN {
    local %ENV = %ENV;
    delete @ENV{qw(PERL_NDEBUG NDEBUG)};
    require Carp::Assert;
    Carp::Assert->import;
}

eval { assert(1==0) if DEBUG; };
like $@, '/^Assertion failed/i';


eval { assert(1==1); };
is $@, '';


eval { assert(Dogs->isa('People'), 'Dogs are people, too!') };
like $@, '/Dogs are people, too!/';


eval { should('this', 'this') };
is $@, '';


eval { should('this', 'that') };
like $@, '/^Assertion \(.*\) failed/i';


eval { shouldnt('this', 'that') };
is $@, '';


eval { shouldnt('up', 'up') };
like $@, '/^Assertion \(.*\) failed/i';
