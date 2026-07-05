use strict;
use warnings;
use Test::More;
use Chorus::Frame;

sub reset_registry { Chorus::Frame::_reset() }

# ---------------------------------------------------------------------------
# 1. _ON_DELETE hook is called after delete()
# ---------------------------------------------------------------------------

reset_registry();

my $called = 0;
my $f = Chorus::Frame->new(
    tag       => 'active',
    _ON_DELETE => sub { $called++ },
);

$f->delete('tag');
is($called, 1, '_ON_DELETE hook is called after delete()');

# ---------------------------------------------------------------------------
# 2. _ON_DELETE receives the deleted slot name
# ---------------------------------------------------------------------------

reset_registry();

my $deleted_slot;
my $g = Chorus::Frame->new(
    color     => 'red',
    _ON_DELETE => sub { $deleted_slot = $_[0] },
);

$g->delete('color');
is($deleted_slot, 'color', '_ON_DELETE receives the deleted slot name');

# ---------------------------------------------------------------------------
# 3. $SELF is the frame inside _ON_DELETE
# ---------------------------------------------------------------------------

reset_registry();

my $self_in_hook;
my $h = Chorus::Frame->new(
    label     => 'test',
    _ON_DELETE => sub { $self_in_hook = $SELF },
);

$h->delete('label');
is($self_in_hook, $h, '$SELF inside _ON_DELETE is the frame itself');

# ---------------------------------------------------------------------------
# 4. delete() on a non-existent slot does not crash
# ---------------------------------------------------------------------------

reset_registry();

my $i = Chorus::Frame->new(color => 'blue');
eval { $i->delete('nonexistent') };
ok(!$@, 'delete() on non-existent slot does not die');

# ---------------------------------------------------------------------------
# 5. fmatch no longer finds the frame for deleted slot
# ---------------------------------------------------------------------------

reset_registry();

my $j = Chorus::Frame->new(status => 'active');
my @before = fmatch(slot => 'status');
is(scalar @before, 1, 'fmatch finds frame before delete');

$j->delete('status');
my @after = fmatch(slot => 'status');
is(scalar @after, 0, 'fmatch does not find frame after delete');

done_testing();
