#!/usr/bin/perl -w

use strict;
use Test;
use Business::CINS;

BEGIN { plan tests => 72 }

# Bad length
foreach ('R92940*110', 'S0007720', 'L20427#100', 'U380R10') {
  my $cn = Business::CINS->new($_);
  ok($cn->is_valid, '', "  Expected an error, but CINS $_ seems to be valid.");
  ok($Business::CINS::ERROR, qr/^CINS .* 9 characters/,
     "  Got an unexpected error: $Business::CINS::ERROR.");
  ok($cn->error, qr/^CINS .* 9 characters/,
     "  Got an unexpected error: ".$cn->error);
}

# Bad Domicile Code in position 1
foreach ('98055KAP0', 'Z39993AD6', 'O4768JAA4') {
  my $cn = Business::CINS->new($_);
  ok($cn->is_valid, '', "  Expected an error, but CINS $_ seems to be valid.");
  ok($Business::CINS::ERROR, qr/^First character/,
     "  Got an unexpected error: $Business::CINS::ERROR.");
  ok($cn->error, qr/^First character/,
     "  Got an unexpected error: ".$cn->error);
}

# Non-numeric in position 2-4
#  foreach ('YA85632AB5', 'G9B930QAA4', 'Y7E18VAA40') {
#    my $cn = Business::CINS->new($_);
#    ok($cn->is_valid, '', "  Expected an error, but CINS $_ seems to be valid.");
#    ok($Business::CINS::ERROR, qr/^Characters 2-4/,
#       "  Got an unexpected error: $Business::CINS::ERROR.");
#    ok($cn->error, qr/^Characters 2-4/,
#       "  Got an unexpected error: ".$cn->error);
#  }

# Bad char in position 4-8
foreach ('Y485g32A5', 'G989l0QA4', 'Y731&VAA0') {
  my $cn = Business::CINS->new($_);
  ok($cn->is_valid, '', "  Expected an error, but CINS $_ seems to be valid.");
  ok($Business::CINS::ERROR, qr/^Characters 2-8/,
     "  Got an unexpected error: $Business::CINS::ERROR.");
  ok($cn->error, qr/^Characters 2-8/,
     "  Got an unexpected error: ".$cn->error);
}

# Non-numeric check digit
foreach ('Y48532ABS', 'G9893QAAA', 'Y7318AA4O', 'G6954AK6E', 'U2467AC2B'){
  my $cn = Business::CINS->new($_);
  ok($cn->is_valid, '', "  Expected an error, but CINS $_ seems to be valid.");
  ok($Business::CINS::ERROR, qr/^Character 9/,
     "  Got an unexpected error: $Business::CINS::ERROR.");
  ok($cn->error, qr/^Character 9/,
     "  Got an unexpected error: ".$cn->error);
}

# These should fail because of the extra fixed income checks
foreach ('P805KA010', 'Y48562215', 'G98930404', 'Y7318A500') {
  my $cn = Business::CINS->new($_, 1);
  ok($cn->is_valid, '', "  Expected an error, but CINS $_ seems to be valid.");
  ok($Business::CINS::ERROR, qr/^Fixed income issue number/,
     "  Did not get the expected error. Got $Business::CINS::ERROR\n");
  ok($cn->error, qr/^Fixed income issue number/,
     "  Did not get the expected error. Got ".$cn->error);
}

# Bad check digit
foreach ('P805KAP05', 'G468JAA37', 'Y45632AB6', 'Y738VAA45', 'G694PAK68'){
  my $cn = Business::CINS->new($_);
  ok($cn->is_valid, '', "  Expected an error, but CINS $_ seems to be valid.");
  ok($Business::CINS::ERROR, qr/^Check digit (?:in|not )correct/,
     "  Got an unexpected error: $Business::CINS::ERROR.");
  ok($cn->error, qr/^Check digit (?:in|not )correct/,
     "  Got an unexpected error: ".$cn->error);
}

__END__
