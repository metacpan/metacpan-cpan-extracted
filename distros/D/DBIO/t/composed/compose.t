# ABSTRACT: karr #70 WP1 -- DBIO::Storage::Composed C3 class synthesis + collision check
use strict;
use warnings;

use Test::More;
use mro;

use DBIO::Storage::Composed;

# --- a dummy base storage and two dummy layers ---------------------------
{
  package T::C::Base;
  sub new       { bless {}, shift }
  sub greet     { 'base' }
  sub base_only { 'base_only' }
}
{
  package T::C::LayerA;
  use mro 'c3';
  sub from_a { 'a' }
  # override AND chain into the base via next::method
  sub greet  { my $self = shift; 'A(' . $self->next::method(@_) . ')' }
}
{
  package T::C::LayerB;
  use mro 'c3';
  sub from_b { 'b' }
}

my $composed = DBIO::Storage::Composed->compose(
  'T::C::Base', [ 'T::C::LayerA', 'T::C::LayerB' ]
);

ok $composed, 'compose returned a class name';
like $composed, qr/^DBIO::Storage::Composed::/,
  'synthesised in the Composed namespace';

# deterministic name -> idempotent for the same (base, layers) tuple
is $composed,
  DBIO::Storage::Composed->compose('T::C::Base', ['T::C::LayerA','T::C::LayerB']),
  'compose is idempotent for the same (base, layers) tuple';

# --- the composed class isa all three, methods callable ------------------
my $obj = $composed->new;
isa_ok $obj, 'T::C::Base',   'composed instance';
isa_ok $obj, 'T::C::LayerA', 'composed instance';
isa_ok $obj, 'T::C::LayerB', 'composed instance';

is $obj->from_a,    'a',         'layer A own method callable';
is $obj->from_b,    'b',         'layer B own method callable';
is $obj->base_only, 'base_only', 'base method callable through composition';

# --- next::method chains a layer override into the base ------------------
is $obj->greet, 'A(base)', 'layer greet() chains into the base via next::method';

# --- registration order = C3 precedence ---------------------------------
is_deeply
  [ grep { /^T::C::/ } @{ mro::get_linear_isa($composed) } ],
  [ 'T::C::LayerA', 'T::C::LayerB', 'T::C::Base' ],
  'C3 precedence follows registration order (first layer most-specific, base last)';

# --- registry helpers ----------------------------------------------------
is_deeply [ DBIO::Storage::Composed->layers_of($composed) ],
  [ 'T::C::LayerA', 'T::C::LayerB' ],
  'layers_of recovers the layer list, in registration order';

my $entry = DBIO::Storage::Composed->composition_of($composed);
is $entry->{base}, 'T::C::Base', 'composition_of recovers the base';
ok !DBIO::Storage::Composed->composition_of('T::C::Base'),
  'a non-composed class has no registry entry';

# --- no layers -> base returned unchanged --------------------------------
my $unchanged = DBIO::Storage::Composed->compose('T::C::Base', []);
is $unchanged, 'T::C::Base',
  'compose with no layers returns the base unchanged';

# --- collision: two layers each defining the same own method ------------
{
  package T::C::CollideX;
  sub boom   { 'x' }
  sub only_x { 1 }
}
{
  package T::C::CollideY;
  sub boom   { 'y' }
  sub only_y { 1 }
}

eval {
  DBIO::Storage::Composed->compose(
    'T::C::Base', [ 'T::C::CollideX', 'T::C::CollideY' ]
  );
};
my $err = $@;
ok $err, 'colliding layers croak at compose time';
like $err, qr/\bboom\b/,        'collision names the colliding method';
like $err, qr/T::C::CollideX/,  'collision names the first defining package';
like $err, qr/T::C::CollideY/,  'collision names the second defining package';
unlike $err, qr/only_x|only_y/, 'non-colliding own methods are not reported';

# --- a single layer overriding a base method is NOT a collision ---------
{
  package T::C::SoloOverride;
  use mro 'c3';
  sub greet { my $self = shift; 'solo(' . $self->next::method(@_) . ')' }
}
my $solo = DBIO::Storage::Composed->compose(
  'T::C::Base', [ 'T::C::SoloOverride', 'T::C::LayerB' ]
);
ok $solo, 'a single layer overriding a base method composes without collision';
is $solo->new->greet, 'solo(base)',
  'the single overriding layer chains into the base';

# --- two layers overriding the SAME base method still collide -----------
{
  package T::C::OverrideP;
  sub base_only { 'P' }
}
{
  package T::C::OverrideQ;
  sub base_only { 'Q' }
}
eval {
  DBIO::Storage::Composed->compose(
    'T::C::Base', [ 'T::C::OverrideP', 'T::C::OverrideQ' ]
  );
};
like $@, qr/base_only/,
  'two layers overriding the same base method still croak';

# --- recompose keeps the layers, swaps the base -------------------------
{
  package T::C::OtherBase;
  sub new { bless {}, shift }
}
my $recomposed = DBIO::Storage::Composed->recompose($composed, 'T::C::OtherBase');
isa_ok $recomposed->new, 'T::C::OtherBase', 'recompose swapped the base';
isa_ok $recomposed->new, 'T::C::LayerA',    'recompose kept layer A';
isa_ok $recomposed->new, 'T::C::LayerB',    'recompose kept layer B';
is_deeply [ DBIO::Storage::Composed->layers_of($recomposed) ],
  [ 'T::C::LayerA', 'T::C::LayerB' ], 'recompose preserved the layer order';

eval { DBIO::Storage::Composed->recompose('T::C::Base', 'T::C::OtherBase') };
like $@, qr/not a composed storage class/,
  'recompose croaks on a non-composed package';

done_testing;
