######################################################################
# Test suite for Acme::HashKeyOrderBrokenAgain
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Acme::HashKeyOrderBrokenAgain;

 # According to https://rt.cpan.org/Public/Bug/Display.html?id=89278 we need
 # to set the environment variables
 #   PERL_HASH_SEED:    "0"
 #   PERL_PERTURB_KEYS: "NO"
 # and do that *before* the interpreter starts, so let's do that 
 # here and re-invoke ourselves.
if( !exists $ENV{ PERL_PERTURB_KEYS } ) {
    # warn "Re-invoking to set anti-hash-jumbling variables";
    $ENV{ PERL_PERTURB_KEYS } = "NO";
    $ENV{ PERL_HASH_SEED }    = "0";
    exec $^X, $0, @ARGV or die;
}

plan tests => 1;

Acme::HashKeyOrderBrokenAgain::hash_key_order_reproducable();
