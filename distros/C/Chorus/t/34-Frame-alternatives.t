use strict;
use warnings;
use Test::More;
use Chorus::Frame;

sub reset_registry { Chorus::Frame::_reset() }

# ---------------------------------------------------------------------------
# 1. _ALTERNATIVES slot is set and retrievable
# ---------------------------------------------------------------------------

reset_registry();

my $Bat    = Chorus::Frame->new(can_fly => 1, legs => 2, nocturnal => 1);
my $Bird   = Chorus::Frame->new(can_fly => 1, legs => 2, _ALTERNATIVES => [$Bat]);

my $alts = $Bird->{_ALTERNATIVES};
ok(ref($alts) eq 'ARRAY' && scalar(@$alts) == 1, '_ALTERNATIVES slot holds arrayref with one frame');
is($alts->[0], $Bat, '_ALTERNATIVES[0] is $Bat');

# ---------------------------------------------------------------------------
# 2. fselect(_alternatives) restricts the pool to seed + alternatives
# ---------------------------------------------------------------------------

reset_registry();

my $Fish   = Chorus::Frame->new(can_fly => 0, legs => 0);
my $Bat2   = Chorus::Frame->new(can_fly => 1, legs => 2, nocturnal => 1);
my $Bird2  = Chorus::Frame->new(can_fly => 1, legs => 2, _ALTERNATIVES => [$Bat2]);

# $Fish is in the global registry but NOT in the Bird2 network
my $result = fselect(can_fly => 1, _alternatives => $Bird2);
ok(defined $result, 'fselect(_alternatives) finds a match');
isnt($result, $Fish, 'fselect(_alternatives) does not return frame outside the network');

# ---------------------------------------------------------------------------
# 3. Best match within the network is selected
# ---------------------------------------------------------------------------

reset_registry();

my $Bat3   = Chorus::Frame->new(can_fly => 1, legs => 2, nocturnal => 1);
my $Bird3  = Chorus::Frame->new(can_fly => 1, legs => 2, _ALTERNATIVES => [$Bat3]);

# nocturnal => 1 matches only Bat3 → Bat3 scores higher
my $best = fselect(can_fly => 1, nocturnal => 1, _alternatives => $Bird3);
is($best, $Bat3, 'fselect(_alternatives) selects best match within the network');

# ---------------------------------------------------------------------------
# 4. _all + _alternatives returns all network candidates with score >= 1
# ---------------------------------------------------------------------------

reset_registry();

my $Bat4   = Chorus::Frame->new(can_fly => 1, legs => 2, nocturnal => 1);
my $Bird4  = Chorus::Frame->new(can_fly => 1, legs => 2, _ALTERNATIVES => [$Bat4]);

my @all = fselect(can_fly => 1, _alternatives => $Bird4, _all => 1);
is(scalar @all, 2, '_all + _alternatives returns all matching frames in the network');

done_testing();
