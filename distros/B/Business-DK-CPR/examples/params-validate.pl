#!/usr/bin/perl -w

# $Id$

use strict;
use warnings;
use Params::Validate qw(:all);
use Business::DK::CPR qw(validateCPR);

eval {
    check_cpr(cpr => 1501721111);
};

if ($@) {
    print "CPR is not valid - $@\n";
}

eval {
    check_cpr(cpr => 1501720000);
};

if ($@) {
    print "CPR is not valid - $@\n";
}

sub check_cpr {
    validate( @_,
    { cpr =>
        { callbacks =>
            { 'validate_cpr' => sub { validateCPR($_[0]); } } } } );
    
    print $_[1]." is a valid CPR\n";

}
