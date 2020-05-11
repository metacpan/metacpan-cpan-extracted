use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Name

=cut

=abstract

Name Class for Perl 5

=cut

=includes

method: dist
method: file
method: format
method: label
method: lookslike_a_file
method: lookslike_a_label
method: lookslike_a_package
method: lookslike_a_path
method: lookslike_a_pragma
method: new
method: package
method: path

=cut

=synopsis

  use Data::Object::Name;

  my $name = Data::Object::Name->new('FooBar/Baz');

=cut

=description

This package provides methods for converting "name" strings.

=cut

=method dist

The dist method returns a package distribution representation of the name.

=signature dist

dist() : Str

=example-1 dist

  # given: synopsis

  my $dist = $name->dist; # FooBar-Baz

=cut

=method file

The file method returns a file representation of the name.

=signature file

file() : Str

=example-1 file

  # given: synopsis

  my $file = $name->file; # foo_bar__baz

=cut

=method format

The format method calls the specified method passing the result to the core
L</sprintf> function with itself as an argument.

=signature format

format(Str $method, Str $format) : Str

=example-1 format

  # given: synopsis

  my $file = $name->format('file', '%s.t'); # foo_bar__baz.t

=cut

=method label

The label method returns a label (or constant) representation of the name.

=signature label

label() : Str

=example-1 label

  # given: synopsis

  my $label = $name->label; # FooBar_Baz

=cut

=method lookslike_a_file

The lookslike_a_file method returns truthy if its state resembles a filename.

=signature lookslike_a_file

lookslike_a_file() : Bool

=example-1 lookslike_a_file

  # given: synopsis

  my $is_file = $name->lookslike_a_file; # falsy

=cut

=method lookslike_a_label

The lookslike_a_label method returns truthy if its state resembles a label (or
constant).

=signature lookslike_a_label

lookslike_a_label() : Bool

=example-1 lookslike_a_label

  # given: synopsis

  my $is_label = $name->lookslike_a_label; # falsy

=cut

=method lookslike_a_package

The lookslike_a_package method returns truthy if its state resembles a package
name.

=signature lookslike_a_package

lookslike_a_package() : Bool

=example-1 lookslike_a_package

  # given: synopsis

  my $is_package = $name->lookslike_a_package; # falsy

=cut

=method lookslike_a_path

The lookslike_a_path method returns truthy if its state resembles a file path.

=signature lookslike_a_path

lookslike_a_path() : Bool

=example-1 lookslike_a_path

  # given: synopsis

  my $is_path = $name->lookslike_a_path; # truthy

=cut

=method lookslike_a_pragma

The lookslike_a_pragma method returns truthy if its state resembles a pragma.

=signature lookslike_a_pragma

lookslike_a_pragma() : Bool

=example-1 lookslike_a_pragma

  # given: synopsis

  my $is_pragma = $name->lookslike_a_pragma; # falsy

=example-2 lookslike_a_pragma

  use Data::Object::Name;

  my $name = Data::Object::Name->new('[strict]');

  my $is_pragma = $name->lookslike_a_pragma; # truthy

=cut

=method new

The new method instantiates the class and returns an object.

=signature new

new(Str $arg) : Object

=example-1 new

  use Data::Object::Name;

  my $name = Data::Object::Name->new;

=cut

=example-2 new

  use Data::Object::Name;

  my $name = Data::Object::Name->new('FooBar');

=cut

=method package

The package method returns a package name representation of the name given.

=signature package

package() : Str

=example-1 package

  # given: synopsis

  my $package = $name->package; # FooBar::Baz

=cut

=method path

The path method returns a path representation of the name.

=signature path

path() : Str

=example-1 path

  # given: synopsis

  my $path = $name->path; # FooBar/Baz

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'dist', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'FooBar-Baz';

  $result
});

$subs->example(-1, 'file', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'foo_bar__baz';

  $result
});

$subs->example(-1, 'format', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'foo_bar__baz.t';

  $result
});

$subs->example(-1, 'label', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'FooBar_Baz';

  $result
});

$subs->example(-1, 'lookslike_a_file', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'lookslike_a_label', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'lookslike_a_package', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'lookslike_a_path', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lookslike_a_pragma', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'lookslike_a_pragma', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'new', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'package', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'FooBar::Baz';

  $result
});

$subs->example(-1, 'path', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'FooBar/Baz';

  $result
});

ok 1 and done_testing;
