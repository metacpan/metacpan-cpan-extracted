use strict;
use warnings;
use Test::More;
use Chorus::Frame;

sub reset_registry { Chorus::Frame::_reset() }

# ---------------------------------------------------------------------------
# 1. complete() with no _TERMINAL_SLOTS returns undef
# ---------------------------------------------------------------------------

reset_registry();

my $f = Chorus::Frame->new(color => 'blue');
ok(!defined $f->complete, 'complete() returns undef when no _TERMINAL_SLOTS');

# ---------------------------------------------------------------------------
# 2. All terminal slots filled → complete() returns 1
# ---------------------------------------------------------------------------

reset_registry();

my $proto = Chorus::Frame->new(_TERMINAL_SLOTS => ['color', 'size']);
my $inst  = Chorus::Frame->new(_ISA => $proto, color => 'blue', size => 'large');
is($inst->complete, 1, 'complete() returns 1 when all terminal slots are filled');

# ---------------------------------------------------------------------------
# 3. Missing terminal slot → complete() returns undef
# ---------------------------------------------------------------------------

reset_registry();

my $proto2   = Chorus::Frame->new(_TERMINAL_SLOTS => ['color', 'size']);
my $partial  = Chorus::Frame->new(_ISA => $proto2, color => 'red');
ok(!defined $partial->complete, 'complete() returns undef when a terminal slot is missing');

# ---------------------------------------------------------------------------
# 4. _TERMINAL_SLOTS inherited from grandparent
# ---------------------------------------------------------------------------

reset_registry();

my $grandparent = Chorus::Frame->new(_TERMINAL_SLOTS => ['weight']);
my $parent      = Chorus::Frame->new(_ISA => $grandparent);
my $child       = Chorus::Frame->new(_ISA => $parent, weight => '10kg');
is($child->complete, 1, 'complete() resolves _TERMINAL_SLOTS from grandparent');

# ---------------------------------------------------------------------------
# 5. Procedural slot counts as filled
# ---------------------------------------------------------------------------

reset_registry();

my $proto3 = Chorus::Frame->new(_TERMINAL_SLOTS => ['label']);
my $inst3  = Chorus::Frame->new(_ISA => $proto3, label => sub { 'computed' });
is($inst3->complete, 1, 'complete() counts a procedural slot as filled');

done_testing();
