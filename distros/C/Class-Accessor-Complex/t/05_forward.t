#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 4;

package Test01;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_object_accessors(
    'Some::Foo' => {
        slot       => 'an_object',
        comp_mthds => [qw(do_this do_that)]
    }
);

package Some::Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_accessors(qw(text));

sub do_this {
    my ($self, $suffix) = @_;
    sprintf "%s %s", $self->text, $suffix;
}
use constant do_that => 42;

package main;
my $test01 = Test01->new;
can_ok(
    'Test01', qw(
      an_object do_this do_that
      )
);
my $t = $test01->an_object(text => 'foobar')->do_this('baz');
isa_ok($test01->an_object, 'Some::Foo');
is($t,               'foobar baz', 'forward do_this');
is($test01->do_that, 42,           'forward do_that');
