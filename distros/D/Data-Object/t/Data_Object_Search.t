use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Search

=cut

=abstract

Search Class for Perl 5

=cut

=includes

method: captures
method: count
method: initial
method: last_match_end
method: last_match_start
method: matched
method: named_captures
method: postmatched
method: prematched
method: regexp
method: string

=cut

=synopsis

  package main;

  use Data::Object::Search;

  my $search = Data::Object::Search->new([
    '(?^:(test))',
    'this is a test',
    1,
    [
      10,
      10
    ],
    [
      14,
      14
    ],
    {},
    'this is a test'
  ]);

=cut

=libraries

Data::Object::Types

=cut

=inherits

Data::Object::Array

=cut

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Proxyable
Data::Object::Role::Throwable

=cut

=description

This package provides methods for manipulating search data.

=cut

=method captures

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation..

=signature captures

captures() : ArrayRef

=example-1 captures

  # given: synopsis

  $search->captures; # ['test']

=cut

=method count

The count method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation..

=signature count

count() : Num

=example-1 count

  # given: synopsis

  $search->count; # 1

=cut

=method initial

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation..

=signature initial

initial() : Str

=example-1 initial

  # given: synopsis

  $search->initial; # this is a test

=cut

=method last_match_end

The last_match_end method returns an array of offset positions into the string
where the capture(s) stopped matching from the result object which contains
information about the results of the regular expression operation..

=signature last_match_end

last_match_end() : Maybe[ArrayRef[Int]]

=example-1 last_match_end

  # given: synopsis

  $search->last_match_end; # [14, 14]

=cut

=method last_match_start

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation..

=signature last_match_start

last_match_start() : Maybe[ArrayRef[Int]]

=example-1 last_match_start

  # given: synopsis

  $search->last_match_start; # [10, 10]

=cut

=method matched

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation..

=signature matched

matched() : Maybe[Str]

=example-1 matched

  # given: synopsis

  $search->matched; # test

=cut

=method named_captures

The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation..

=signature named_captures

named_captures() : HashRef

=example-1 named_captures

  # given: synopsis

  $search->named_captures; # {}

=cut

=method postmatched

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation..

=signature postmatched

postmatched() : Maybe[Str]

=example-1 postmatched

  # given: synopsis

  $search->postmatched; # ''

=cut

=method prematched

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation..

=signature prematched

prematched() : Maybe[Str]

=example-1 prematched

  # given: synopsis

  $search->prematched; # 'this is a '

=cut

=method regexp

The regexp method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation..

=signature regexp

regexp() : RegexpRef

=example-1 regexp

  # given: synopsis

  $search->regexp; # qr/(test)/

=cut

=method string

The string method returns the string matched against the regular expression
from the result object which contains information about the results of the
regular expression operation..

=signature string

string() : Str

=example-1 string

  # given: synopsis

  $search->string; # this is a test

=cut

package main;

my $subs = testauto(__FILE__);

$subs->package;
$subs->document;
$subs->libraries;
$subs->inherits;
$subs->attributes;
$subs->routines;
$subs->functions;
$subs->types;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Search');

  $result
});

$subs->example(-1, 'captures', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['test'];

  $result
});

$subs->example(-1, 'count', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'initial', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'this is a test';

  $result
});

$subs->example(-1, 'last_match_end', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [14, 14];

  $result
});

$subs->example(-1, 'last_match_start', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [10, 10];

  $result
});

$subs->example(-1, 'matched', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'test';

  $result
});

$subs->example(-1, 'named_captures', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

$subs->example(-1, 'postmatched', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, '';

  $result
});

$subs->example(-1, 'prematched', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'this is a ';

  $result
});

$subs->example(-1, 'regexp', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like "$result", qr/\(test\)/;

  $result
});

$subs->example(-1, 'string', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
