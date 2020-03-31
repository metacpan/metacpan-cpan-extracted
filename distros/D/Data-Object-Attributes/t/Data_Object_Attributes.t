use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Attributes

=cut

=abstract

Attribute Builder for Perl 5

=cut

=synopsis

  package Example;

  use Moo;

  use Data::Object::Attributes;

  has 'data';

  package main;

  my $example = Example->new;

=cut

=description

This package provides options for defining class attributes. Specifically, this
package wraps the C<has> attribute keyword and adds shortcuts and enhancements.
If no directives are specified, the attribute is declared as C<read-write> and
C<optional>.

=cut

=scenario has

This package supports the C<has> keyword function and all of its
configurations. See the L<Moo> documentation for more details.

=example has

  package Example::Has;

  use Moo;

  has 'data' => (
    is => 'ro',
    isa => sub { die }
  );

  package Example::HasData;

  use Moo;

  use Data::Object::Attributes;

  extends 'Example::Has';

  has '+data' => (
    is => 'ro',
    isa => sub { 1 }
  );

  package main;

  my $example = Example::HasData->new(data => time);

=cut

=scenario has-is

This package supports the C<is> directive, used to denote whether the attribute
is read-only or read-write. See the L<Moo> documentation for more details.

=example has-is

  package Example::HasIs;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro'
  );

  package main;

  my $example = Example::HasIs->new(data => time);

=cut

=scenario has-isa

This package supports the C<isa> directive, used to define the type constraint
to validate the attribute against. See the L<Moo> documentation for more
details.

=example has-isa

  package Example::HasIsa;

  use Moo;
  use registry;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    isa => 'Str' # e.g. Types::Standard::Str
  );

  package main;

  my $example = Example::HasIsa->new(data => time);

=cut

=scenario has-req

This package supports the C<req> and C<required> directives, used to denote if
an attribute is required or optional. See the L<Moo> documentation for more
details.

=example has-req

  package Example::HasReq;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    req => 1 # required
  );

  package main;

  my $example = Example::HasReq->new(data => time);

=cut

=scenario has-opt

This package supports the C<opt> and C<optional> directives, used to denote if
an attribute is optional or required. See the L<Moo> documentation for more
details.

=example has-opt

  package Example::HasOpt;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    opt => 1
  );

  package main;

  my $example = Example::HasOpt->new(data => time);

=cut

=scenario has-bld

This package supports the C<bld> and C<builder> directives, expects a C<1>, a
method name, or coderef and builds the attribute value if it wasn't provided to
the constructor. See the L<Moo> documentation for more details.

=example has-bld

  package Example::HasBld;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    bld => 1
  );

  method _build_data() {

    return time;
  }

  package main;

  my $example = Example::HasBld->new;

=cut

=scenario has-clr

This package supports the C<clr> and C<clearer> directives expects a C<1> or a
method name of the clearer method. See the L<Moo> documentation for more
details.

=example has-clr

  package Example::HasClr;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    clr => 1
  );

  package main;

  my $example = Example::HasClr->new(data => time);

  # $example->clear_data;

=cut

=scenario has-crc

This package supports the C<crc> and C<coerce> directives denotes whether an
attribute's value should be automatically coerced. See the L<Moo> documentation
for more details.

=example has-crc

  package Example::HasCrc;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    crc => sub {'0'}
  );

  package main;

  my $example = Example::HasCrc->new(data => time);

=cut

=scenario has-def

This package supports the C<def> and C<default> directives expects a
non-reference or a coderef to be used to build a default value if one is not
provided to the constructor. See the L<Moo> documentation for more details.

=example has-def

  package Example::HasDef;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    def => '0'
  );

  package main;

  my $example = Example::HasDef->new;

=cut

=scenario has-mod

This package supports the C<mod> and C<modify> directives denotes whether a
pre-existing attribute's definition is being modified. This ability is not
supported by the L<Moo> object superclass.

=example has-mod

  package Example::HasNomod;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'rw',
    opt => 1
  );

  package Example::HasMod;

  use Moo;

  use Data::Object::Attributes;

  extends 'Example::HasNomod';

  has data => (
    is => 'ro',
    req => 1,
    mod => 1
  );

  package main;

  my $example = Example::HasMod->new;

=cut

=scenario has-hnd

This package supports the C<hnd> and C<handles> directives denotes the methods
created on the object which dispatch to methods available on the attribute's
object. See the L<Moo> documentation for more details.

=example has-hnd

  package Example::Time;

  use Moo;
  use routines;

  method maketime() {

    return time;
  }

  package Example::HasHnd;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    hnd => ['maketime']
  );

  package main;

  my $example = Example::HasHnd->new(data => Example::Time->new);

=cut

=scenario has-lzy

This package supports the C<lzy> and C<lazy> directives denotes whether the
attribute will be constructed on-demand, or on-construction. See the L<Moo>
documentation for more details.

=example has-lzy

  package Example::HasLzy;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    def => sub {time},
    lzy => 1
  );

  package main;

  my $example = Example::HasLzy->new;

=cut

=scenario has-new

This package supports the C<new> directive, if truthy, denotes that the
attribute will be constructed on-demand, i.e. is lazy, with a builder named
new_{attribute}. This ability is not supported by the L<Moo> object superclass.

=example has-new

  package Example::HasNew;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    new => 1
  );

  fun new_data($self) {

    return time;
  }

  package main;

  my $example = Example::HasNew->new(data => time);

=cut

=scenario has-pre

This package supports the C<pre> and C<predicate> directives expects a C<1> or
a method name and generates a method for checking the existance of the
attribute. See the L<Moo> documentation for more details.

=example has-pre

  package Example::HasPre;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    pre => 1
  );

  package main;

  my $example = Example::HasPre->new(data => time);

=cut

=scenario has-rdr

This package supports the C<rdr> and C<reader> directives denotes the name of
the method to be used to "read" and return the attribute's value. See the
L<Moo> documentation for more details.

=example has-rdr

  package Example::HasRdr;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    rdr => 'get_data'
  );

  package main;

  my $example = Example::HasRdr->new(data => time);

=cut

=scenario has-tgr

This package supports the C<tgr> and C<trigger> directives expects a C<1> or a
coderef and is executed whenever the attribute's value is changed. See the
L<Moo> documentation for more details.

=example has-tgr

  package Example::HasTgr;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    tgr => 1
  );

  method _trigger_data() {
    $self->{triggered} = 1;

    return $self;
  }

  package main;

  my $example = Example::HasTgr->new(data => time);

=cut

=scenario has-use

This package supports the C<use> directive denotes that the attribute will be
constructed on-demand, i.e. is lazy, using a custom builder meant to perform
service construction. This directive exists to provide a simple dependency
injection mechanism for class attributes. This ability is not supported by the
L<Moo> object superclass.

=example has-use

  package Example::HasUse;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    use => ['service', 'time']
  );

  method service($type, @args) {
    $self->{serviced} = 1;

    return time if $type eq 'time';
  }

  package main;

  my $example = Example::HasUse->new;

=cut

=scenario has-wkr

This package supports the C<wkr> and C<weak_ref> directives is used to denote if
the attribute's value should be weakened. See the L<Moo> documentation for more
details.

=example has-wkr

  package Example::HasWkr;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    wkr => 1
  );

  package main;

  my $data = do {
    my ($a, $b);

    $a = { time => time };
    $b = { time => $a };

    $a->{time} = $b;
    $a
  };

  my $example = Example::HasWkr->new(data => $data);

=cut

=scenario has-wrt

This package supports the C<wrt> and C<writer> directives denotes the name of
the method to be used to "write" and return the attribute's value. See the
L<Moo> documentation for more details.

=example has-wrt

  package Example::HasWrt;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    wrt => 'set_data'
  );

  package main;

  my $example = Example::HasWrt->new;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->data;
  ok $result->data(time);
  ok $result->data;

  $result
});

$subs->scenario('has', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;

  $result
});

$subs->scenario('has-is', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;

  $result
});

$subs->scenario('has-isa', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;

  $result
});

$subs->scenario('has-req', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;

  $result
});

$subs->scenario('has-opt', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;

  $result
});

$subs->scenario('has-bld', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;

  $result
});

$subs->scenario('has-clr', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;
  ok $result->clear_data;
  ok !$result->data;

  $result
});

$subs->scenario('has-crc', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->data;
  is $result->data, '0';

  $result
});

$subs->scenario('has-def', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->data;
  is $result->data, '0';

  $result
});

$subs->scenario('has-mod', fun($tryable) {
  $tryable->default(fun($error) {
    "$error" =~ /required/i ? 'errored' : 'unknown';
  });
  ok my $result = $tryable->result;
  is $result, 'errored';

  $result
});

$subs->scenario('has-hnd', fun($tryable) {
  ok my $result = $tryable->result;
  ok my $object = $result->data;
  ok $object->can('maketime');
  ok $result->maketime;

  $result
});

$subs->scenario('has-lzy', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->{data};
  ok $result->data;
  ok $result->{data};

  $result
});

$subs->scenario('has-new', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;

  $result
});

$subs->scenario('has-pre', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->has_data;

  $result
});

$subs->scenario('has-rdr', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->get_data;

  $result
});

$subs->scenario('has-tgr', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;
  is $result->{triggered}, 1;

  $result
});

$subs->scenario('has-use', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->data;
  is $result->{serviced}, 1;

  $result
});

$subs->scenario('has-wkr', fun($tryable) {
  require Scalar::Util;

  ok my $result = $tryable->result;
  ok $result->data;
  ok Scalar::Util::isweak($result->{data});

  $result
});

$subs->scenario('has-wrt', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->set_data(time);
  ok $result->data;

  $result
});

ok 1 and done_testing;
