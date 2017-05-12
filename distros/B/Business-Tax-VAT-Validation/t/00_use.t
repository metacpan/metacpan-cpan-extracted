#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

use Business::Tax::VAT::Validation;

my $hvat=Business::Tax::VAT::Validation->new();
if (ref $hvat){
    ok(1);
} else {
    warn "Error creating vat object: ".($hvat || 'undef')
}
exit;
__END__
