use Test::More tests=>3;

BEGIN {
  use_ok qw(Acme::Tie::Formatted);
}

ok exists $main::{format}, "hash was properly exported";
can_ok 'Acme::Tie::Formatted', qw(TIEHASH FETCH);
