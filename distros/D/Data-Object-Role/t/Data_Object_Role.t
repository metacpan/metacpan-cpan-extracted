use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role

=cut

=abstract

Role Builder for Perl 5

=cut

=synopsis

  package Identity;

  use Data::Object::Role;

  package Example;

  use Moo;

  with 'Identity';

  package main;

  my $example = Example->new;

=cut

=inherits

Moo

=cut

=description

This package modifies the consuming package making it a role.

=cut

=scenario has

This package supports the C<has> keyword, which is used to declare role
attributes, which can be accessed and assigned to using the built-in
getter/setter or by the object constructor. See L<Moo> for more information.

=example has

  package HasIdentity;

  use Data::Object::Role;

  has id => (
    is => 'ro'
  );

  package HasExample;

  use Moo;

  with 'HasIdentity';

  package main;

  my $example = HasExample->new;

=cut

=scenario requires

This package supports the C<requires> keyword, which is used to declare methods
which must exist in the consuming package. See L<Moo> for more information.

=example requires

  package EntityRequires;

  use Data::Object::Role;

  requires 'execute';

  package RequiresExample;

  use Moo;

  with 'EntityRequires';

  sub execute {

    # does something ...
  }

  package main;

  my $example = RequiresExample->new;

=scenario with

This package supports the C<with> keyword, which is used to declare roles to be
used and compose into your role. See L<Moo> for more information.

=example with

  package WithEntity;

  use Data::Object::Role;

  package WithIdentity;

  use Data::Object::Role;

  with 'WithEntity';

  package WithExample;

  use Moo;

  with 'WithIdentity';

  package main;

  my $example = WithExample->new;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('has', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('with', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('requires', fun($tryable) {
  $tryable->default(fun($error) {
    "$error" =~ /missing execute/;
  });
  ok my $result = $tryable->result;
  ok $result->can('execute');

  $result
});

ok 1 and done_testing;
