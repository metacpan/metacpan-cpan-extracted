#!/usr/bin/perl -w

use strict;
use Test;
use Business::CUSIP;

BEGIN { plan tests => 75 }

# Bad length
foreach ('92940*11', '00077202', '20427#10', '38080R10') {
  my $csp = Business::CUSIP->new($_);
  ok($csp->is_valid, '', "  Expected an error, but CUSIP $_ seems to be valid.");
  ok($Business::CUSIP::ERROR, qr/^CUSIP .* 9 characters/,
     "  Got an unexpected error: $Business::CUSIP::ERROR.");
  ok($csp->error, qr/^CUSIP .* 9 characters/,
     "  Got an unexpected error: ".$csp->error);
}

# Non-numeric in position 1-3
foreach ('G2940*118', '0@0772020', '20A27#109', '38O80R103') {
  my $csp = Business::CUSIP->new($_);
  ok($csp->is_valid, '', "  Expected an error, but CUSIP $_ seems to be valid.");
  ok($Business::CUSIP::ERROR, qr/^Characters 1-3/,
     "  Got an unexpected error: $Business::CUSIP::ERROR.");
  ok($csp->error, qr/^Characters 1-3/,
     "  Got an unexpected error: ".$csp->error);
}

# Bad char in position 4-8
foreach ('92940*l18', '000772o20', '204!7#109', '3808&R103') {
  my $csp = Business::CUSIP->new($_);
  ok($csp->is_valid, '', "  Expected an error, but CUSIP $_ seems to be valid.");
  ok($Business::CUSIP::ERROR, qr/^Characters 4-8/,
     "  Got an unexpected error: $Business::CUSIP::ERROR.");
  ok($csp->error, qr/^Characters 4-8/,
     "  Got an unexpected error: ".$csp->error);
}

# Non-numeric check digit
foreach ('92940*11B', '00077202O', '20427#10$', '38080R10E') {
  my $csp = Business::CUSIP->new($_);
  ok($csp->is_valid, '', "  Expected an error, but CUSIP $_ seems to be valid.");
  ok($Business::CUSIP::ERROR, qr/^Character 9/,
     "  Got an unexpected error: $Business::CUSIP::ERROR.");
  ok($csp->error, qr/^Character 9/,
     "  Got an unexpected error: ".$csp->error);
}

# These should fail because of the I1O0 business
foreach ('92940*118', '000772020', '20427#109', '38080R103', '8169951D6') {
  my $csp = Business::CUSIP->new($_, 1);
  ok($csp->is_valid, '', "  Expected an error, but CUSIP $_ seems to be valid.");
  ok($Business::CUSIP::ERROR, qr/^Fixed income CUSIP cannot contain/,
     "  Did not get the expected error. Got $Business::CUSIP::ERROR\n");
  ok($csp->error, qr/^Fixed income CUSIP cannot contain/,
     "  Did not get the expected error. Got ".$csp->error);
}

# Bad check digit
foreach ('92940*117', '000772029', '20427#108', '38080R102') {
  my $csp = Business::CUSIP->new($_);
  ok($csp->is_valid, '', "  Expected an error, but CUSIP $_ seems to be valid.");
  ok($Business::CUSIP::ERROR, qr/^Check digit (?:in|not )correct/,
     "  Got an unexpected error: $Business::CUSIP::ERROR.");
  ok($csp->error, qr/^Check digit (?:in|not )correct/,
     "  Got an unexpected error: ".$csp->error);
}

__END__
