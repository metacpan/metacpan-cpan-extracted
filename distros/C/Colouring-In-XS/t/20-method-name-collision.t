use strict;
use warnings;
use Test::More tests => 8;

use Colouring::In::XS;

package Foreign;
sub new    { bless { val => $_[1] }, $_[0] }
sub colour { return "[foreign-colour:$_[0]->{val}]" }
sub mix    { return "[foreign-mix:$_[0]->{val}+$_[1]]" }
sub shade  { return "[foreign-shade:$_[0]->{val}]" }
sub tint   { return "[foreign-tint:$_[0]->{val}]" }
sub fade   { return "[foreign-fade:$_[0]->{val}]" }
sub toHEX  { return "[foreign-toHEX:$_[0]->{val}]" }
sub toRGB  { return "[foreign-toRGB:$_[0]->{val}]" }

package main;

my $f = Foreign->new('x');
is($f->colour,    '[foreign-colour:x]', 'foreign ->colour falls through');
is($f->shade,     '[foreign-shade:x]',  'foreign ->shade falls through');
is($f->tint,      '[foreign-tint:x]',   'foreign ->tint falls through');
is($f->fade,      '[foreign-fade:x]',   'foreign ->fade falls through');
is($f->toHEX,     '[foreign-toHEX:x]',  'foreign ->toHEX falls through');
is($f->toRGB,     '[foreign-toRGB:x]',  'foreign ->toRGB falls through');
is($f->mix('y'),  '[foreign-mix:x+y]',  'foreign ->mix falls through');

# Sanity: real Colouring object still dispatches through our pp
my $c = Colouring::In::XS->new('#fff');
is($c->toHEX, '#fff', 'colouring ->toHEX still works');
