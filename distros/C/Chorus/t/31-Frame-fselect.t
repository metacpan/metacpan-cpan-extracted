use strict;
use warnings;
use Test::More;
use Chorus::Frame;

# Isolate each test block from leftover frames
sub reset_registry { Chorus::Frame::_reset() }

# ---------------------------------------------------------------------------
# 1. fselect is exported
# ---------------------------------------------------------------------------

ok(defined &fselect, 'fselect is exported by Chorus::Frame');

# ---------------------------------------------------------------------------
# 2. Basic single-slot selection
# ---------------------------------------------------------------------------

reset_registry();

my $bird = Chorus::Frame->new(type => 'bird', can_fly => 1,  color => 'red');
my $fish = Chorus::Frame->new(type => 'fish', can_fly => 0,  color => 'blue');
my $bat  = Chorus::Frame->new(type => 'bat',  can_fly => 1,  color => 'black');

my $got = fselect(can_fly => 1);
ok(defined $got, 'fselect returns a frame when a match exists');
is($got->can_fly, 1, 'selected frame has can_fly => 1');

# ---------------------------------------------------------------------------
# 3. Multi-slot scoring — best match wins
# ---------------------------------------------------------------------------

reset_registry();

my $robin   = Chorus::Frame->new(type => 'bird', can_fly => 1, color => 'red');
my $penguin = Chorus::Frame->new(type => 'bird', can_fly => 0, color => 'black');
my $plane   = Chorus::Frame->new(type => 'machine', can_fly => 1, color => 'white');

# robin matches 2 slots (can_fly=1, color=red); penguin matches 0; plane matches 1
my $best = fselect(can_fly => 1, color => 'red');
is($best->type, 'bird',  'best match is the frame with highest score');
is($best->color, 'red',  'best match has correct color');

# ---------------------------------------------------------------------------
# 4. No match returns undef / empty list
# ---------------------------------------------------------------------------

reset_registry();

Chorus::Frame->new(color => 'green');

my $none = fselect(color => 'purple');
ok(!defined $none, 'fselect returns undef when nothing matches');

my @none = fselect(color => 'purple');
is(scalar @none, 0, 'fselect returns empty list in list context when nothing matches');

# ---------------------------------------------------------------------------
# 5. _all option returns all candidates ranked best-first
# ---------------------------------------------------------------------------

reset_registry();

my $f1 = Chorus::Frame->new(color => 'blue', size => 'large');  # score 2
my $f2 = Chorus::Frame->new(color => 'blue', size => 'small');  # score 1
my $f3 = Chorus::Frame->new(color => 'red');                     # score 0 — excluded

my @all = fselect(color => 'blue', size => 'large', _all => 1);
is(scalar @all, 2, '_all returns all frames with score >= 1');
is($all[0]->size, 'large', 'best-scoring frame is first');

# scalar context with _all returns arrayref
my $aref = fselect(color => 'blue', size => 'large', _all => 1);
ok(ref($aref) eq 'ARRAY', '_all in scalar context returns arrayref');
is(scalar @$aref, 2, 'arrayref contains 2 frames');

# ---------------------------------------------------------------------------
# 6. _from restricts the search space
# ---------------------------------------------------------------------------

reset_registry();

my $a = Chorus::Frame->new(color => 'blue', role => 'A');
my $b = Chorus::Frame->new(color => 'blue', role => 'B');
my $c = Chorus::Frame->new(color => 'blue', role => 'C');

my $restricted = fselect(color => 'blue', _from => [$a, $c]);
ok(defined $restricted, '_from: a frame is found');
ok($restricted->role ne 'B', '_from: frame B excluded from search space');

# ---------------------------------------------------------------------------
# 7. _min => 0 includes frames with zero matching slots
# ---------------------------------------------------------------------------

reset_registry();

my $red_f   = Chorus::Frame->new(color => 'red');
my $green_f = Chorus::Frame->new(color => 'green');
my $large_f = Chorus::Frame->new(size  => 'large');   # no color slot

my @with_min0 = fselect(color => 'red', _all => 1, _min => 0);
ok(scalar @with_min0 >= 3, '_min => 0 includes frames that match zero slots');

# ---------------------------------------------------------------------------
# 8. Procedural slot resolved correctly
# ---------------------------------------------------------------------------

reset_registry();

my $dynamic = Chorus::Frame->new(
    label    => 'dynamic',
    category => sub { 'animal' },
);

my $static = Chorus::Frame->new(
    label    => 'static',
    category => 'machine',
);

my $sel = fselect(category => 'animal');
is($sel->label, 'dynamic', 'fselect resolves procedural slot via get()');

done_testing();
