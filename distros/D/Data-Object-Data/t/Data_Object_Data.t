use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Data

=cut

=abstract

Podish Parser for Perl 5

=cut

=attributes

data: ro, opt, Str
file: ro, opt, Str
from: ro, opt, Str

=cut

=includes

method: content
method: contents
method: item
method: list
method: list_item
method: parser
method: pluck

=cut

=synopsis

  package main;

  use Data::Object::Data;

  my $data = Data::Object::Data->new(
    file => 't/Data_Object_Data.t'
  );

=cut

=description

This package provides methods for parsing and extracting pod-like sections from
any file or package. The pod-like syntax allows for using these sections
anywhere in the source code and having Perl properly ignoring them.

=cut

=method content

The content method the pod-like section where the name matches the given
string.

=signature content

content(Str $name) : ArrayRef[Str]

=example-1 content

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/content.pod'
  );

  $data->content('name');

  # ['Example #1']

=cut

=method contents

The contents method returns all pod-like sections that start with the given
string, e.g. C<pod> matches C<=pod foo>. This method returns an arrayref of
data for the matched sections. Optionally, you can filter the results by name
by providing an additional argument.

=signature contents

contents(Str $list, Str $name) : ArrayRef[ArrayRef]

=example-1 contents

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->contents('name');

 # [['Example #1'], ['Example #2']]

=cut

=method item

The item method returns metadata for the pod-like section that matches the
given string.

=signature item

item(Str $name) : HashRef

=example-1 item

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/content.pod'
  );

  $data->item('name');

  # {
  #   index => 1,
  #   data => ['Example #1'],
  #   list => undef,
  #   name => 'name'
  # }

=cut

=method list

The list method returns metadata for each pod-like section that matches the
given string.

=signature list

list(Str $name) : ArrayRef

=example-1 list

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->list('name');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # },
  # {
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=cut

=method list_item

The list_item method returns metadata for the pod-like sections that matches
the given list name and argument.

=signature list_item

list_item(Str $list, Str $item) : ArrayRef[HashRef]

=example-1 list_item

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->list_item('name', 'example-2');

  # [{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=cut

=method parser

The parser method extracts pod-like sections from a given string and returns an
arrayref of metadata.

=signature parser

parser(Str $string) : ArrayRef

=example-1 parser

  # given: synopsis

  $data->parser("=pod\n\nContent\n\n=cut");

  # [{
  #   index => 1,
  #   data => ['Content'],
  #   list => undef,
  #   name => 'pod'
  # }]

=cut

=method pluck

The pluck method splices and returns metadata for the pod-like section that
matches the given list or item by name. Splicing means that the parsed dataset
will be reduced each time this method returns data, making this useful with
iterators and reducers.

=signature pluck

pluck(Str $type, Str $item) : ArrayRef[HashRef]

=example-1 pluck

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->pluck('list', 'name');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # },{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=example-2 pluck

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->pluck('item', 'example-1');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # }]

  $data->pluck('item', 'example-2');

  # [{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=example-3 pluck

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->pluck('list', 'name');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # },{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

  $data->pluck('list', 'name');

  # []

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Data');
  is $result->file, 't/Data_Object_Data.t';
  ok grep { ref eq 'HASH' } @{$result->data};
  ok !$result->from;

  $result
});

$subs->example(-1, 'content', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['Example #1'];

  $result
});

$subs->example(-1, 'contents', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['Example #1'], ['Example #2']];

  $result
});

$subs->example(-1, 'item', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    index => 1,
    data => ['Example #1'],
    list => undef,
    name => 'name'
  };

  $result
});

$subs->example(-1, 'list', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [{
    index => 1,
    data => ['Example #1'],
    list => 'name',
    name => 'example-1'
  },
  {
    index => 2,
    data => ['Example #2'],
    list => 'name',
    name => 'example-2'
  }];

  $result
});

$subs->example(-1, 'list_item', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [{
    index => 2,
    data => ['Example #2'],
    list => 'name',
    name => 'example-2'
  }];

  $result
});

$subs->example(-1, 'parser', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [{
    index => 1,
    data => ['Content'],
    list => undef,
    name => 'pod'
  }];

  $result
});

$subs->example(-1, 'pluck', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [{
    index => 1,
    data => ['Example #1'],
    list => 'name',
    name => 'example-1'
  },{
    index => 2,
    data => ['Example #2'],
    list => 'name',
    name => 'example-2'
  }];

  $result
});

$subs->example(-2, 'pluck', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [{
    index => 2,
    data => ['Example #2'],
    list => 'name',
    name => 'example-2'
  }];

  $result
});

$subs->example(-3, 'pluck', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

ok 1 and done_testing;
