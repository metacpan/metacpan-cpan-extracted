use strict;
use warnings;

use FindBin;
use Test::More;
use Test::Exception;

use lib "$FindBin::Bin/lib";

BEGIN {
  package A::First;

  use Class::C3::Componentised::ApplyHooks;

  AFTER_APPLY { $_[0]->after("a $_[1]") };
  AFTER_APPLY { $_[0]->after("b $_[1]") };
  BEFORE_APPLY { $_[0]->before("a $_[1]") };
  BEFORE_APPLY { $_[0]->before("b $_[1]") };

  1;
}

BEGIN {
  package A::Second;

  use base 'A::First';

  use Class::C3::Componentised::ApplyHooks
    -after_apply => sub { $_[0]->after("a $_[1]") },
    -before_apply => sub { $_[0]->before("a $_[1]") },
    qw(BEFORE_APPLY AFTER_APPLY);

  AFTER_APPLY { $_[0]->after("b $_[1]") };
  BEFORE_APPLY { $_[0]->before("b $_[1]") };
  1;
}


BEGIN {
  package A::Third;

  use base 'A::Second';

  1;
}

BEGIN {
  package A::Class::Second;

  use base 'Class::C3::Componentised';
  use Test::More;

  our @before;
  our @after;

  sub component_base_class { 'A' }
  __PACKAGE__->load_components('Second');

  sub before { push @before, $_[1] }
  sub after { push @after, $_[1] }

  is_deeply(\@before, [
    'b A::Second',
    'a A::Second',
    'b A::First',
    'a A::First',
  ], 'before runs in the correct order');
  is_deeply(\@after, [
    'a A::First',
    'b A::First',
    'a A::Second',
    'b A::Second',
  ], 'after runs in the correct order');
}

BEGIN {
  package A::Class::Third;

  use base 'Class::C3::Componentised';
  use Test::More;

  our @before;
  our @after;

  sub component_base_class { 'A' }
  __PACKAGE__->load_components('Third');

  sub before { push @before, $_[1] }
  sub after { push @after, $_[1] }

  is_deeply(\@before, [
    'b A::Second',
    'a A::Second',
    'b A::First',
    'a A::First',
  ], 'before runs in the correct order');
  is_deeply(\@after, [
    'a A::First',
    'b A::First',
    'a A::Second',
    'b A::Second',
  ], 'after runs in the correct order');
}

done_testing;
