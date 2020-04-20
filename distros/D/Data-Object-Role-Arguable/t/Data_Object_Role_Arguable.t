use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Arguable

=cut

=abstract

Arguable Role for Perl 5 Plugin Classes

=cut

=includes

method: packargs
method: unpackargs

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Arguable';

  has name => (
    is => 'ro'
  );

  has options => (
    is => 'ro'
  );

  sub argslist {
    ('name', '@options')
  }

  package main;

  my $example = Example->new(['james', 'red', 'white', 'blue']);

=cut

=libraries

Types::Standard

=cut

=description

This package provides a mechanism for unpacking an argument list and creating a
data structure suitable for passing to the consumer constructor. The
C<argslist> routine should return a list of attribute names in the order to be
parsed. An attribute name maybe prefixed with B<"@"> to denote that all remaining
items should be assigned to an arrayref, e.g. C<@options>, or B<"%"> to denote
that all remaining items should be assigned to a hashref, e.g. C<%options>.

=cut

=method packargs

The packargs method uses C<argslist> to return a data structure suitable for
passing to the consumer constructor.

=signature packargs

packargs() : HashRef

=example-1 packargs

  package main;

  my $example = Example->new;

  my $attributes = $example->packargs('james', 'red', 'white', 'blue');

=cut

=method unpackargs

The unpackargs method uses C<argslist> to return a list of arguments from the
consumer class instance in the appropriate order.

=signature unpackargs

unpackargs(Any @args) : (Any)

=example-1 unpackargs

  package main;

  my $example = Example->new(['james', 'red', 'white', 'blue']);

  my $arguments = [$example->unpackargs];

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Data::Object::Role::Arguable');
  ok $result->can('argslist');
  is $result->name, 'james';
  is_deeply $result->options, ['red', 'white', 'blue'];

  $result
});

$subs->example(-1, 'packargs', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {name => 'james', options => ['red', 'white', 'blue']};

  $result
});

$subs->example(-1, 'unpackargs', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['james', 'red', 'white', 'blue'];

  (@$result)
});

ok 1 and done_testing;
