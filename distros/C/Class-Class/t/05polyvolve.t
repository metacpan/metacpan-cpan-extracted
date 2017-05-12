# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 9; }

use strict;
use vars qw ($s);

use Test;

# Test 1:
eval {
  package X;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (Class::Class);

  %MEMBERS = (X => '$');

  use Class::Class;

  sub initialize ($) {
    my $self = shift;

    $self->X (__PACKAGE__) unless $self->X;

    return $self;
  }


  package Y;

  use strict;
  use vars qw (@ISA);

  @ISA = qw (X);

  # No initializer or members to test inheritance (lack there of :-).


  package Z;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (X);

  %MEMBERS = (Z => '$');

  sub initialize ($) {
    my $self = shift;

    $self->Z (__PACKAGE__) unless $self->Z;

    return $self;
  }


  package Q;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (Y Z);

  %MEMBERS = (Q => '$');

  sub initialize ($) {
    my $self = shift;

    $self->Q (__PACKAGE__) unless $self->Q;

    $self = $self->polyvolve ('T'); # no such class
    $self = $self->polyvolve ('S::no::such::subclass')
      if ref $self eq __PACKAGE__; # I'm still myself

    return $self;
  }


  package R;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (Q);

  %MEMBERS = (R => '$');

  sub initialize ($) {
    my $self = shift;

    $self->R (__PACKAGE__) unless $self->R;

    return $self;
  }


  package S;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (R);

  %MEMBERS = (S => '$');

  sub initialize ($) {
    my $self = shift;

    $self->S (__PACKAGE__) unless $self->S;

    return $self;
  }

  1;
};
ok (not $@);

# Test 2 - 4:
eval { $s = new Q; };
ok (not $@);
ok ($s);
ok (ref $s, 'S');

# Test 5 - 9:
for (qw (X Z Q R S)) {
  no strict qw (refs);

  ok ($s->{$_}, $_);
}
