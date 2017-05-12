#!/sw/bin/perl

use strict;
use warnings;
use Test::More tests => 36;
use Data::Dumper;

BEGIN { use_ok('Config::Validate', 'validate') };

my @valid = qw(0 1 t f true false on off y n yes no);
push(@valid, "yes ", " yes");
push(@valid, map { uc($_) } @valid);
test_success($_) foreach @valid;

my @invalid = qw(2 -1 tr fa onn yno);
push(@invalid, undef);
test_failure($_) foreach @invalid;


sub test_success {
  my $value = shift;

  my $schema = { booleantest => { type => 'boolean' } };
  my $data = { booleantest => $value };
  eval { validate($data, $schema) };
  is($@, '', "'$value' validated correctly");
}

sub test_failure {
  my $value = shift;

  my $schema = { booleantest => { type => 'boolean' } };
  my $data = { booleantest => $value };
  eval { validate($data, $schema) };
  if (not defined $value) {
    $value = "<undef>";
  }
  like($@, qr/\[\/booleantest/, "'$value' didn't validate (expected)");
}
