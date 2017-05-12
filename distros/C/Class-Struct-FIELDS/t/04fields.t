# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 18 }

require 5.005_64;
use strict;
use warnings;

use Test;

# Field tests.

use Class::Struct::FIELDS;

# Test 1:
use Class::Struct::FIELDS Wilma => [],
  aa => '$';
use Class::Struct::FIELDS Elements =>
  { aa => '$',
    bb => '\$',
    cc => '@',
    dd => '\@',
    ee => '%',
    ff => '\%',
    gg => '&',
    hh => '\&',
    ii => '/',
    jj => '\/',
    kk => 'Wilma',
    ll => '\Wilma' };
ok ($::po = Elements::->new);

# Test 2:
ok (not defined $::po->aa);

# Test 3:
ok (ref $::po->bb eq 'SCALAR');

# Test 4:
ok (ref $::po->cc eq 'ARRAY');

# Tests 5-6:
push @{$::po->dd}, 'larry wall';
ok (ref $::po->dd (0) eq 'SCALAR');
ok ($::po->dd->[0] eq 'larry wall');

# Test 7:
ok (ref $::po->ee eq 'HASH');

# Tests 8-9:
${$::po->ff}{larry} = 'wall';
ok (ref $::po->ff ('larry') eq 'SCALAR');
ok ($::po->ff->{larry} eq 'wall');

# Test 10:
ok (not defined $::po->gg);

# Tests 11-12:
ok (ref ${$::po->hh (sub { 1 })} eq 'CODE');
ok (${$::po->hh}->( ) == 1);

# Test 13:
ok (not defined $::po->ii);

# Tests 14-15:
ok (ref ${$::po->jj (qr/^$/)} eq 'Regexp');
ok ('' =~ ${$::po->jj});

# Test 16:
ok (ref $::po->kk eq 'Wilma');

# Tests 17-18:
${$::po->ll}->aa (1);
ok (ref ${$::po->ll} eq 'Wilma');
ok (${$::po->ll}->aa == 1);
