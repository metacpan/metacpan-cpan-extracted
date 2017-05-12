package TestInit;

use Class::AccessorMaker {
  ran_init => 0 }, "new_init";

sub init {
  my $self = shift;
  $self->ran_init($self->ran_init + 1);
}

1;

package TestInit::Priv;

use Class::AccessorMaker::Private {
  ran_init => 0 }, "new_init";

sub init {
  my $self = shift;
  $self->ran_init($self->ran_init + 1);
}

1;

package main;

use Test::More tests => 4;
use strict;

ok(my $test = TestInit->new(), "new OK");
ok($test = TestInit::Priv->new(), "Private new OK");

is($test->ran_init, 1, "init OK");
is($test->ran_init, 1, "Private init OK");
