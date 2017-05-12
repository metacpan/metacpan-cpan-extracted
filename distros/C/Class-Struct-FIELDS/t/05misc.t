# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 18 }

require 5.005_64;
use strict;
use warnings;

use Test;

# Miscellaneous tests.

use Class::Struct::FIELDS;

# Tests 1-2:
# User overrides generated accessors.
use Class::Struct::FIELDS Koala => [],
  ee => '%';
sub Wallaby::dorf ($;$$);
use Class::Struct::FIELDS Wallaby => [],
  dorf => 'Koala';
sub Wallaby::dorf ($;$$) {
  my Wallaby $self = $_[0];
  $self->{dorf} ||= Koala::->new;

  if (@_ == 3) {
    $self->{dorf}->ee ($_[1], $_[2]);

  } elsif (@_ == 2) {
    $self->{dorf}->ee ($_[1]);

  } else {
    $self->{dorf}->ee;
  }
}
ok ($::po = Wallaby::->new);
ok ($::po->dorf (apple => 'core') eq 'core');

# Tests 3-4:
# UNIVERSAL::isa broken in 5.6.0.
use Class::Struct::FIELDS qw(Alice);
use Class::Struct::FIELDS Bob => [qw(Alice)];
use Class::Struct::FIELDS Carl => { alice => 'Alice' };
$::po = Carl::->new;
eval { $::po->alice (Alice::->new) };
ok (ref $::po->alice eq 'Alice');
eval { $::po->alice (Bob::->new) };
ok (ref $::po->alice eq 'Bob');

# Tests 5-6:
# User override accesses "hidden" member:
sub Pachyderm::dorf ($;$);
use Class::Struct::FIELDS Pachyderm => [],
  dorf => '$';
sub Pachyderm::dorf ($;$) {
  my Pachyderm $self = shift;

  return $self->__dorf (@_);
}

$::po = Pachyderm::->new;
ok (not defined $::po->dorf);
ok ($::po->dorf ('trumpet') eq 'trumpet');

# Test 7:
# User override accesses "hidden" member w/v5.6.0 bug:
sub Elephant::dorf ($;$);
use Class::Struct::FIELDS Elephant => [],
  dorf => '$';
sub Elephant::dorf ($;$) {
  # This silliness is due to a bug in 5.6.0: it thinks you can't
  # fiddle with @_ if you've given it a prototype.  XXX
  my @args = @_;
  $args[1] *= 2 if @args == 2 and defined $args[1];
  @_ = @args;
  goto &Elephant::__dorf;
}

$::po = Elephant::->new;
ok ($::po->dorf (2) == 4);

# Tests 8-10:
# EXPERIMENTAL  XXX
use Class::Struct::FIELDS Kanga => { ary => '+@' };
my @ary;
ok ($::po = tie @ary, 'Kanga');
ok (1 == push @ary, 3);
ok ($ary[0] == 3);
undef $::po;
untie @ary;

# Tests 11-13:
# EXPERIMENTAL  XXX
use Class::Struct::FIELDS Roo => { ary => '+@Kanga' };
ok ($::po = tie @ary, 'Roo');
ok (1 == push @ary, Kanga::->new);
ok (ref $ary[1] eq 'Kanga'); # auto-create
undef $::po;
untie @ary;

# Test 14:
sub Rary::as_string { ref $_[0] || "$_[0]" };
use Class::Struct::FIELDS qw(Rary);
$::po = Rary::->new;
ok ("$::po" eq 'Rary');

# Tests 15-16:
# EXPERIMENTAL  XXX
use Class::Struct::FIELDS Oitiluke => { ary => '+%' };
my %hash;
ok ($::po = tie %hash, 'Oitiluke');
ok (3 == ($hash{key} = 3));
undef $::po;
untie %hash;

# Tests 17-18:
# EXPERIMENTAL  XXX
use Class::Struct::FIELDS Bigby => { ary => '+%Oitiluke' };
ok ($::po = tie %hash, 'Bigby');
ok (ref ($hash{key} = Oitiluke::->new) eq 'Oitiluke');
undef $::po;
untie %hash;

1;
