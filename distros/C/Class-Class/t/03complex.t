# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 7; }

use strict;
use vars qw ($q);

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

    $self->X ('X') unless $self->X;

    return $self;
  }


  package Y;

  use strict;
  use vars qw (@ISA);

  @ISA = qw (X);

  # No initialize or members to make sure inheritance (lack thereof :-) works.

  package Z;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (X);

  %MEMBERS = (Z => '$');

  sub initialize ($) {
    my $self = shift;

    $self->Z ('Z') unless $self->Z;

    return $self;
  }

  package Q;

  use strict;
  use vars qw (@ISA %MEMBERS);

  @ISA = qw (Y Z);

  %MEMBERS = (Q => '$');

  sub initialize ($) {
    my $self = shift;

    $self->Q ('Q') unless $self->Q;

    return $self;
  }

  1;
};
ok (not $@);

# Test 2 - 4:
eval { $q = new Q; };
ok (not $@);
ok ($q);
ok (ref $q, 'Q');

# Test 5 - 7:
for (qw (X Z Q)) {
  no strict qw (refs);

  ok ($q->{$_}, $_);
}
