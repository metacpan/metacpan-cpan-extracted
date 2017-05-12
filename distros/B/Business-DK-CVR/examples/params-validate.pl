#!/usr/bin/perl -w

# $Id$

use strict;
use warnings;
use Params::Validate qw(:all);

use lib qw(lib);
use Business::DK::CVR qw(validateCVR);

eval {
    check_cvr(cvr => 27355021);
};

if ($@) {
    print "CVR is not valid - $@\n";
}

eval {
    check_cvr(cvr => 27355020);
};

if ($@) {
    print "CVR is not valid - $@\n";
}

sub check_cvr {
    validate( @_,
    { cvr =>
        { callbacks =>
            { 'validate_cvr' => sub { validateCVR($_[0]); } } } } );
    
    print $_[1]." is a valid CVR\n";

}
