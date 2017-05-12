use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 8;
use Clustericious::Config;

create_config_ok confa => <<'EOF1';
---
a: valuea
b: valueb
c:
  x: y
EOF1

my $confa = Clustericious::Config->new('confa');

create_config_ok confb => <<'EOF2';
---
a: valuea
EOF2

my $confb = Clustericious::Config->new('confb');

is $confa->a, 'valuea', "value a set";
is $confa->b, 'valueb', "value b set";

do {

  no warnings 'redefine';
  local *Carp::cluck = sub { };

  eval { $confa->missing };
  like $@, qr/'missing' configuration item not found/, "missing a value";
  note $@;

  eval { $confb->missing };
  like $@, qr/'missing' configuration item not found/, "missing a value";
  note $@;

  eval { $confb->b };
  like $@, qr/'b' configuration item not found/, "no autovivivication in other classes";
  note $@;

};

is $confb->c(default => ''), '', "no autovivication in other classes";

